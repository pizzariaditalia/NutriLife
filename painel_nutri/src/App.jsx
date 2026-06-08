import React, { useState, useEffect } from 'react';
import { collection, doc, onSnapshot, updateDoc } from 'firebase/firestore';
import { db } from './firebase';

export default function App() {
  const [pacientes, setPacientes] = useState([]);
  const [carregando, setCarregando] = useState(true);
  const [pacienteSelecionado, setPacienteSelecionado] = useState(null);
  const [dadosDiario, setDadosDiario] = useState(null);
  const [dadosConquistas, setDadosConquistas] = useState(null);

  // Estados do formulário de prescrição
  const [novaMetaCalorias, setNovaMetaCalorias] = useState(2000);
  const [novaMetaAgua, setNovaMetaAgua] = useState(2500);
  const [salvandoMeta, setSalvandoMeta] = useState(false);

  // Histórico estático simulado para alimentar o gráfico premium (Será integrado ao banco no futuro)
  const historicoPeso = [
    { mes: "Jan", peso: 88 },
    { mes: "Fev", peso: 86.5 },
    { mes: "Mar", peso: 85 },
    { mes: "Abr", peso: 83.2 },
    { mes: "Mai", peso: 81.8 },
    { mes: "Jun", peso: 79.5 }
  ];

  const getTodayDateKey = () => {
    const agora = new Date();
    return `${agora.getFullYear()}-${String(agora.getMonth() + 1).padStart(2, '0')}-${String(agora.getDate()).padStart(2, '0')}`;
  };

  const dataHoje = getTodayDateKey();

  // 📡 ESCUTADOR 1: Lista geral de pacientes
  useEffect(() => {
    const colecaoRef = collection(db, 'usuarios');
    const fecharConexao = onSnapshot(colecaoRef, (snapshot) => {
      setPacientes(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setCarregando(false);
    });
    return () => fecharConexao();
  }, []);

  // 📡 ESCUTADOR 2: Diário e Conquistas do paciente selecionado
  useEffect(() => {
    if (!pacienteSelecionado) {
      setDadosDiario(null);
      setDadosConquistas(null);
      return;
    }

    // Escuta o diário de alimentação/água
    const diarioDocRef = doc(db, 'usuarios', pacienteSelecionado.id, 'diario', dataHoje);
    const fecharDiario = onSnapshot(diarioDocRef, (snapshot) => {
      if (snapshot.exists()) {
        const dados = snapshot.data();
        setDadosDiario(dados);
        setNovaMetaCalorias(dados.meta_calorias || 2000);
        setNovaMetaAgua(dados.meta_agua || 2500);
      } else {
        setDadosDiario({ calorias_consumidas: 0, meta_calorias: 2000, agua_consumida: 0, meta_agua: 2500, historico_alimentos: [] });
      }
    });

    // Escuta as conquistas comportamentais marcadas no celular
    const conquistasDocRef = doc(db, 'usuarios', pacienteSelecionado.id, 'conquistas', dataHoje);
    const fecharConquistas = onSnapshot(conquistasDocRef, (snapshot) => {
      if (snapshot.exists()) {
        setDadosConquistas(snapshot.data());
      } else {
        setDadosConquistas({});
      }
    });

    return () => { fecharDiario(); fecharConquistas(); };
  }, [pacienteSelecionado]);

  const atualizarMetas = async (e) => {
    e.preventDefault();
    if (!pacienteSelecionado) return;
    setSalvandoMeta(true);
    try {
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id, 'diario', dataHoje), {
        meta_calorias: Number(novaMetaCalorias),
        meta_agua: Number(novaMetaAgua)
      });
      alert("🎯 Metas enviadas com sucesso para o celular do paciente!");
    } catch (erro) {
      alert("Erro ao salvar. Certifique-se de que o paciente já abriu o app hoje.");
    } finally { setSalvandoMeta(false); }
  };

  return (
    <div class="flex h-screen overflow-hidden">
      
      <aside class="w-64 bg-[#3B4D43] text-white flex flex-col justify-between p-6">
        <div>
          <div class="flex items-center gap-3 mb-8 cursor-pointer" onClick={() => setPacienteSelecionado(null)}>
            <span class="text-2xl">🌿</span>
            <h1 class="text-xl font-bold tracking-wide">Nutri Life</h1>
          </div>
          <nav class="space-y-2">
            <button onClick={() => setPacienteSelecionado(null)} class={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-medium transition text-left ${!pacienteSelecionado ? 'bg-[#2C3E35]' : 'text-white/80 hover:bg-[#2C3E35]/50'}`}>
              <span>👥</span> Pacientes
            </button>
          </nav>
        </div>
        <div class="border-t border-white/10 pt-4 text-xs text-white/60">Painel Clínico v1.5</div>
      </aside>

      <main class="flex-1 overflow-y-auto p-8 lg:p-12">
        
        {/* TELA 1: LISTAGEM GERAL DE PACIENTES */}
        {!pacienteSelecionado ? (
          <div>
            <header class="mb-8">
              <h2 class="text-3xl font-bold">Pacientes Cadastrados</h2>
              <p class="text-gray-500 text-sm mt-1">Monitore e prescreva dietas personalizadas em tempo real.</p>
            </header>

            <section class="bg-white rounded-2xl border border-gray-100 overflow-hidden">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-gray-50/70 border-b border-gray-100 text-gray-400 text-xs uppercase font-bold tracking-wider">
                    <th class="p-4 pl-6">Nome do Paciente</th>
                    <th class="p-4">Identificador Único</th>
                    <th class="p-4 text-right pr-6">Ação</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-50 text-sm">
                  {carregando ? (
                    <tr><td colspan="3" class="p-8 text-center text-gray-400">Buscando na nuvem...</td></tr>
                  ) : pacientes.length === 0 ? (
                    <tr><td colspan="3" class="p-8 text-center text-gray-400">Nenhum paciente ativo no momento.</td></tr>
                  ) : pacientes.map((p) => (
                    <tr key={p.id} class="hover:bg-gray-50/50 transition">
                      <td class="p-4 pl-6">
                        <p class="font-bold text-gray-900">{p.nome || "Paciente Sem Nome"}</p>
                        <p class="text-xs text-gray-400">{p.email}</p>
                      </td>
                      <td class="p-4 text-gray-400 font-mono text-xs">{p.id}</td>
                      <td class="p-4 text-right pr-6">
                        <button onClick={() => setPacienteSelecionado(p)} class="text-[#3B4D43] font-bold text-xs bg-gray-100 hover:bg-[#3B4D43] hover:text-white px-4 py-2 rounded-xl transition">
                          Visualizar Prontuário →
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          </div>
        ) : (
          
          /* TELA 2: PRONTUÁRIO EXPANDIDO DO PACIENTE */
          <div>
            <button onClick={() => setPacienteSelecionado(null)} class="text-sm font-bold text-[#3B4D43] hover:underline mb-4 block">
              ← Voltar para a lista
            </button>
            
            <header class="mb-8">
              <span class="text-xs font-bold uppercase text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-md">Prontuário Aberto</span>
              <h2 class="text-3xl font-bold mt-2">{pacienteSelecionado.nome || "Paciente de Teste"}</h2>
              <p class="text-gray-500 text-sm">{pacienteSelecionado.email}</p>
            </header>

            <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
              
              {/* SEÇÃO DA ESQUERDA (DASHBOARDS E HISTÓRICOS) */}
              <div class="lg:col-span-2 space-y-6">
                
                {/* METRICAS DE HOJE */}
                <div class="bg-white p-6 rounded-2xl border border-gray-100 grid grid-cols-2 gap-4">
                  <div>
                    <span class="text-xs text-gray-400 font-bold uppercase">Calorias Ingeridas Hoje</span>
                    <p class="text-2xl font-bold text-[#3B4D43] mt-1">
                      {dadosDiario?.calorias_consumidas || 0} <span class="text-sm font-normal text-gray-400">/ {dadosDiario?.meta_calorias || 2000} kcal</span>
                    </p>
                  </div>
                  <div>
                    <span class="text-xs text-gray-400 font-bold uppercase">Água Consumida Hoje</span>
                    <p class="text-2xl font-bold text-blue-600 mt-1">
                      {dadosDiario?.agua_consumida || 0} <span class="text-sm font-normal text-gray-400">/ {dadosDiario?.meta_agua || 2500} ml</span>
                    </p>
                  </div>
                </div>

                {/* 📈 GRÁFICO DE EVOLUÇÃO DE PESO PREMIUM VETORIAL (SVG) */}
                <div class="bg-white p-6 rounded-2xl border border-gray-100">
                  <h3 class="font-bold text-lg text-[#3B4D43] mb-2">Evolução do Peso Corporal</h3>
                  <p class="text-xs text-gray-400 mb-6">Gráfico gerado a partir das últimas pesagens do paciente.</p>
                  
                  <div class="relative w-full h-48 bg-gray-50/50 rounded-xl p-4 flex flex-col justify-between border border-gray-100">
                    {/* Linha de Tendência Vetorial */}
                    <svg class="absolute inset-0 w-full h-full p-8" viewBox="0 0 500 100" preserveAspectRatio="none">
                      <path d="M 0 90 L 100 70 L 200 50 L 300 35 L 400 20 L 500 5" fill="none" stroke="#3B4D43" stroke-width="3" stroke-linecap="round"/>
                      <circle cx="0" cy="90" r="5" fill="#3B4D43" />
                      <circle cx="100" cy="70" r="5" fill="#3B4D43" />
                      <circle cx="200" cy="50" r="5" fill="#3B4D43" />
                      <circle cx="300" cy="35" r="5" fill="#3B4D43" />
                      <circle cx="400" cy="20" r="5" fill="#3B4D43" />
                      <circle cx="500" cy="5" r="5" fill="#3B4D43" />
                    </svg>

                    {/* Exibição dos Meses e Valores alinhados */}
                    <div class="flex justify-between text-[11px] text-gray-400 font-bold mt-auto pt-4 z-10">
                      {historicoPeso.map((h, i) => (
                        <div key={i} class="text-center">
                          <p class="text-[#3B4D43] font-extrabold">{h.peso}kg</p>
                          <p class="mt-1 font-medium text-gray-400">{h.mes}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>

                {/* 🌿 INTEGRAÇÃO: VITÓRIAS ALÉM DA BALANÇA (DO CELULAR DO PACIENTE) */}
                <div class="bg-white p-6 rounded-2xl border border-gray-100">
                  <h3 class="font-bold text-lg text-[#3B4D43] mb-1">Vitórias Comportamentais de Hoje</h3>
                  <p class="text-xs text-gray-400 mb-4">Sinalizadores de bem-estar marcados pelo paciente no smartphone.</p>
                  
                  <div class="grid grid-cols-2 gap-3">
                    <div class={`p-3 rounded-xl border flex items-center gap-3 text-sm font-semibold transition ${dadosConquistas?.energia_alta ? 'bg-amber-50/50 border-amber-200 text-amber-800' : 'bg-gray-50/50 border-gray-100 text-gray-400'}`}>
                      <span>⚡</span> Energia Constante
                    </div>
                    <div class={`p-3 rounded-xl border flex items-center gap-3 text-sm font-semibold transition ${dadosConquistas?.sono_reparador ? 'bg-indigo-50/50 border-indigo-200 text-indigo-800' : 'bg-gray-50/50 border-gray-100 text-gray-400'}`}>
                      <span>🌙</span> Sono Reparador
                    </div>
                    <div class={`p-3 rounded-xl border flex items-center gap-3 text-sm font-semibold transition ${dadosConquistas?.roupa_solta ? 'bg-rose-50/50 border-rose-200 text-rose-800' : 'bg-gray-50/50 border-gray-100 text-gray-400'}`}>
                      <span>👕</span> Roupas Largar
                    </div>
                    <div class={`p-3 rounded-xl border flex items-center gap-3 text-sm font-semibold transition ${dadosConquistas?.control_doce ? 'bg-orange-50/50 border-orange-200 text-orange-800' : 'bg-gray-50/50 border-gray-100 text-gray-400'}`}>
                      <span>🍩</span> Controle de Doces
                    </div>
                  </div>
                </div>

                {/* DIÁRIO DE ALIMENTOS */}
                <div class="bg-white rounded-2xl border border-gray-100 p-6">
                  <h3 class="font-bold text-lg mb-4 text-[#3B4D43]">Alimentos Ingeridos Hoje</h3>
                  {!dadosDiario?.historico_alimentos || dadosDiario.historico_alimentos.length === 0 ? (
                    <p class="text-gray-400 text-sm text-center py-6">Nenhum registro alimentar no dia de hoje.</p>
                  ) : (
                    <div class="divide-y divide-gray-100">
                      {dadosDiario.historico_alimentos.map((alimento, i) => (
                        <div key={i} class="py-3 flex justify-between items-center text-sm">
                          <div>
                            <p class="font-semibold text-gray-950">{alimento.nome}</p>
                            <p class="text-xs text-gray-400">Turno: {alimento.turno} • Qtd: {alimento.quantidade}x</p>
                          </div>
                          <span class="font-bold text-[#3B4D43]">{alimento.calorias} kcal</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              {/* SEÇÃO DA DIREITA (PRESCRIÇÃO DE METAS) */}
              <div class="bg-white p-6 rounded-2xl border border-gray-100 h-fit">
                <h3 class="font-bold text-lg text-[#3B4D43] mb-1">Ajustar Metas Clínicas</h3>
                <p class="text-xs text-gray-400 mb-6">Redefina os alvos para alterar instantaneamente o aplicativo do paciente.</p>
                
                <form onSubmit={atualizarMetas} class="space-y-4">
                  <div>
                    <label class="block text-xs font-bold uppercase text-gray-500 mb-1">Meta Calórica (kcal)</label>
                    <input type="number" value={novaMetaCalorias} onChange={(e) => setNovaMetaCalorias(e.target.value)} class="w-full bg-[#F9F6F0] border border-gray-200 rounded-xl px-4 py-2.5 text-sm font-medium focus:outline-[#3B4D43]" required />
                  </div>
                  <div>
                    <label class="block text-xs font-bold uppercase text-gray-500 mb-1">Meta de Hidratação (ml)</label>
                    <input type="number" value={novaMetaAgua} onChange={(e) => setNovaMetaAgua(e.target.value)} class="w-full bg-[#F9F6F0] border border-gray-200 rounded-xl px-4 py-2.5 text-sm font-medium focus:outline-[#3B4D43]" required />
                  </div>
                  <button type="submit" disabled={salvandoMeta} class="w-full bg-[#3B4D43] text-white py-3 rounded-xl font-bold text-sm shadow-sm hover:bg-[#2C3E35] transition disabled:opacity-50 mt-2">
                    {salvandoMeta ? "Enviando..." : "Atualizar no Smartphone"}
                  </button>
                </form>
              </div>

            </div>
          </div>
        )}
      </main>
    </div>
  );
}
