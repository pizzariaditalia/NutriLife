import React, { useState, useEffect } from 'react';
import { collection, doc, onSnapshot, updateDoc, query, orderBy, limit, setDoc } from 'firebase/firestore';
import { db } from './firebase';

export default function App() {
  const [pacientes, setPacientes] = useState([]);
  const [carregando, setCarregando] = useState(true);
  const [pacienteSelecionado, setPacienteSelecionado] = useState(null);
  const [dadosDiario, setDadosDiario] = useState(null);
  const [dadosConquistas, setDadosConquistas] = useState(null);
  const [historicoPesoReal, setHistoricoPesoReal] = useState([]);

  // Estados das Metas Numéricas
  const [novaMetaCalorias, setNovaMetaCalorias] = useState(2000);
  const [novaMetaAgua, setNovaMetaAgua] = useState(2500);
  const [salvandoMeta, setSalvandoMeta] = useState(false);

  // 🍎 ESTADOS PREMIUM: Prescrição do Plano Alimentar (Fica salvo no perfil do paciente)
  const [planoCafe, setPlanoCafe] = useState("");
  const [planoAlmoco, setPlanoAlmoco] = useState("");
  const [planoLanche, setPlanoLanche] = useState("");
  const [planoJantar, setPlanoJantar] = useState("");
  const [salvandoPlano, setSalvandoPlano] = useState(false);

  const dataHoje = new Date().toISOString().split('T')[0];

  // 📡 ESCUTADOR 1: Lista geral de pacientes
  useEffect(() => {
    return onSnapshot(collection(db, 'usuarios'), (snapshot) => {
      setPacientes(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setCarregando(false);
    });
  }, []);

  // 📡 ESCUTADOR 2: Prontuário, Diário, Conquistas e Plano Alimentar do Paciente
  useEffect(() => {
    if (!pacienteSelecionado) {
      setDadosDiario(null);
      setDadosConquistas(null);
      setHistoricoPesoReal([]);
      setPlanoCafe(""); setPlanoAlmoco(""); setPlanoLanche(""); setPlanoJantar("");
      return;
    }

    // Carrega o Plano Alimentar Prescrito (Fixo no cadastro do usuário)
    if (pacienteSelecionado.plano_alimentar) {
      const p = pacienteSelecionado.plano_alimentar;
      setPlanoCafe(p.cafe || "");
      setPlanoAlmoco(p.almoco || "");
      setPlanoLanche(p.lanche || "");
      setPlanoJantar(p.jantar || "");
    }

    // Escuta consumo de hoje
    const unsubDiario = onSnapshot(doc(db, 'usuarios', pacienteSelecionado.id, 'diario', dataHoje), (snapshot) => {
      if (snapshot.exists()) {
        const dados = snapshot.data();
        setDadosDiario(dados);
        setNovaMetaCalorias(dados.meta_calorias || 2000);
        setNovaMetaAgua(dados.meta_agua || 2500);
      } else {
        setDadosDiario({ calorias_consumidas: 0, meta_calorias: 2000, agua_consumida: 0, meta_agua: 2500, historico_alimentos: [] });
      }
    });

    // Escuta conquistas de hoje
    const unsubConquistas = onSnapshot(doc(db, 'usuarios', pacienteSelecionado.id, 'conquistas', dataHoje), (snapshot) => {
      setDadosConquistas(snapshot.exists() ? snapshot.data() : {});
    });

    // Escuta histórico de peso
    const q = query(collection(db, 'usuarios', pacienteSelecionado.id, 'historico_peso'), orderBy('timestamp', 'asc'), limit(5));
    const unsubPesos = onSnapshot(q, (snapshot) => {
      setHistoricoPesoReal(snapshot.docs.map(doc => doc.data()));
    });

    return () => { unsubDiario(); unsubConquistas(); unsubPesos(); };
  }, [pacienteSelecionado]);

  // 🔥 GRAVAÇÃO 1: Atualiza metas numéricas do dia
  const atualizarMetas = async (e) => {
    e.preventDefault();
    if (!pacienteSelecionado) return;
    setSalvandoMeta(true);
    try {
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id, 'diario', dataHoje), {
        meta_calorias: Number(novaMetaCalorias),
        meta_agua: Number(novaMetaAgua)
      });
      alert("🎯 Metas numéricas atualizadas!");
    } catch (e) { alert("Erro ao salvar metas."); }
    finally { setSalvandoMeta(false); }
  };

  // 🔥 GRAVAÇÃO 2: Salva o Plano Alimentar Definitivo no Firebase
  const salvarPlanoAlimentar = async () => {
    if (!pacienteSelecionado) return;
    setSalvandoPlano(true);
    try {
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id), {
        plano_alimentar: {
          cafe: planoCafe,
          almoco: planoAlmoco,
          lanche: planoLanche,
          jantar: planoJantar
        }
      });
      alert("🍏 Plano Alimentar salvo! Disponível no smartphone do paciente.");
    } catch (e) { alert("Erro ao salvar plano alimentar."); }
    finally { setSalvandoPlano(false); }
  };

  const construirCaminhoSVG = () => {
    if (historicoPesoReal.length < 2) return "";
    const larguraTotal = 500; const alturaTotal = 100;
    const pesos = historicoPesoReal.map(h => h.weight || h.peso);
    const minPeso = Math.min(...pesos) - 2; const maxPeso = Math.max(...pesos) + 2;
    const deltaPeso = maxPeso - minPeso === 0 ? 1 : maxPeso - minPeso;

    return historicoPesoReal.map((h, index) => {
      const pAtual = h.weight || h.peso;
      const x = (index / (historicoPesoReal.length - 1)) * larguraTotal;
      const y = alturaTotal - ((pAtual - minPeso) / deltaPeso) * alturaTotal;
      return `${index === 0 ? 'M' : 'L'} ${x} ${y}`;
    }).join(' ');
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
        <div class="border-t border-white/10 pt-4 text-xs text-white/60">Painel Clínico v2.0</div>
      </aside>

      <main class="flex-1 overflow-y-auto p-8 lg:p-12">
        {!pacienteSelecionado ? (
          <div>
            <header class="mb-8">
              <h2 class="text-3xl font-bold">Pacientes Cadastrados</h2>
              <p class="text-gray-500 text-sm mt-1">Selecione um prontuário para monitoramento em tempo real.</p>
            </header>
            <section class="bg-white rounded-2xl border border-gray-100 overflow-hidden">
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-gray-50/70 border-b border-gray-100 text-gray-400 text-xs uppercase font-bold tracking-wider">
                    <th class="p-4 pl-6">Nome do Paciente</th>
                    <th class="p-4">ID de Registro</th>
                    <th class="p-4 text-right pr-6">Ação</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-50 text-sm">
                  {carregando ? (
                    <tr><td colspan="3" class="p-8 text-center text-gray-400">Buscando na nuvem...</td></tr>
                  ) : pacientes.length === 0 ? (
                    <tr><td colspan="3" class="p-8 text-center text-gray-400">Nenhum paciente cadastrado.</td></tr>
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
          <div>
            <button onClick={() => setPacienteSelecionado(null)} class="text-sm font-bold text-[#3B4D43] hover:underline mb-4 block">← Voltar para a lista</button>
            <header class="mb-8">
              <span class="text-xs font-bold uppercase text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-md">Prontuário Premium</span>
              <h2 class="text-3xl font-bold mt-2">{pacienteSelecionado.nome || "Usuário de Teste"}</h2>
            </header>

            <div class="grid grid-cols-1 xl:grid-cols-3 gap-8">
              {/* COLUNA DA ESQUERDA: GRÁFICOS E DIÁRIO DE HOJE */}
              <div class="xl:col-span-2 space-y-6">
                <div class="bg-white p-6 rounded-2xl border border-gray-100 grid grid-cols-2 gap-4">
                  <div>
                    <span class="text-xs text-gray-400 font-bold uppercase">Calorias Ingeridas</span>
                    <p class="text-2xl font-bold text-[#3B4D43] mt-1">{dadosDiario?.calorias_consumidas || 0} <span class="text-sm font-normal text-gray-400">/ {dadosDiario?.meta_calorias || 2000} kcal</span></p>
                  </div>
                  <div>
                    <span class="text-xs text-gray-400 font-bold uppercase">Água Consumida</span>
                    <p class="text-2xl font-bold text-blue-600 mt-1">{dadosDiario?.agua_consumida || 0} <span class="text-sm font-normal text-gray-400">/ {dadosDiario?.meta_agua || 2500} ml</span></p>
                  </div>
                </div>

                <div class="bg-white p-6 rounded-2xl border border-gray-100">
                  <h3 class="font-bold text-lg text-[#3B4D43] mb-2">Evolução de Peso Corporal</h3>
                  <div class="relative w-full h-36 bg-gray-50/50 rounded-xl p-4 flex flex-col justify-between border border-gray-100">
                    {historicoPesoReal.length < 2 ? (
                      <div class="absolute inset-0 flex items-center justify-center text-sm text-gray-400">Aguardando registros de peso no app...</div>
                    ) : (
                      <>
                        <svg class="absolute inset-0 w-full h-full p-8" viewBox="0 0 500 100" preserveAspectRatio="none">
                          <path d={construirCaminhoSVG()} fill="none" stroke="#3B4D43" stroke-width="3" stroke-linecap="round"/>
                        </svg>
                        <div class="flex justify-between text-[11px] text-gray-400 font-bold mt-auto pt-4 z-10">
                          {historicoPesoReal.map((h, i) => (
                            <div key={i} class="text-center">
                              <p class="text-[#3B4D43] font-extrabold">{h.peso || h.weight}kg</p>
                              <p class="mt-1 font-medium text-gray-400">{h.mes}</p>
                            </div>
                          ))}
                        </div>
                      </>
                    )}
                  </div>
                </div>

                {/* 🍏 NOVO PAINEL DE PRESCRIÇÃO DE CARDÁPIO (DIETBOX STYLE) */}
                <div class="bg-white p-6 rounded-2xl border border-gray-100 space-y-4">
                  <div class="flex justify-between items-center">
                    <div>
                      <h3 class="font-bold text-lg text-[#3B4D43]">Prescrever Plano Alimentar Definitivo</h3>
                      <p class="text-xs text-gray-400">O que você digitar aqui aparecerá estruturado no diário do paciente.</p>
                    </div>
                    <button onClick={salvarPlanoAlimentar} disabled={salvandoPlano} class="bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs px-4 py-2.5 rounded-xl shadow-xs transition">
                      {salvandoPlano ? "Salvando..." : "💾 Salvar Cardápio"}
                    </button>
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label class="block text-xs font-bold uppercase text-gray-500 mb-1">☕ Café da Manhã</label>
                      <textarea value={planoCafe} onChange={(e) => setPlanoCafe(e.target.value)} placeholder="Ex: 2 ovos mexidos + 1 fatia de pão integral com creme de ricota..." class="w-full h-24 bg-[#F9F6F0] border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] resize-none" />
                    </div>
                    <div>
                      <label class="block text-xs font-bold uppercase text-gray-500 mb-1">☀️ Almoço</label>
                      <textarea value={planoAlmoco} onChange={(e) => setPlanoAlmoco(e.target.value)} placeholder="Ex: 150g de frango + 100g de arroz integral + salada à vontade..." class="w-full h-24 bg-[#F9F6F0] border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] resize-none" />
                    </div>
                    <div>
                      <label class="block text-xs font-bold uppercase text-gray-500 mb-1">🍌 Lanche da Tarde</label>
                      <textarea value={planoLanche} onChange={(e) => setPlanoLanche(e.target.value)} placeholder="Ex: 1 banana com 15g de aveia + 30g de Whey Protein..." class="w-full h-24 bg-[#F9F6F0] border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] resize-none" />
                    </div>
                    <div>
                      <label class="block text-xs font-bold uppercase text-gray-500 mb-1">🌙 Jantar</label>
                      <textarea value={planoJantar} onChange={(e) => setPlanoJantar(e.target.value)} placeholder="Ex: Omelete de 3 ovos com espinafre + 100g de batata doce..." class="w-full h-24 bg-[#F9F6F0] border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] resize-none" />
                    </div>
                  </div>
                </div>
              </div>

              {/* SEÇÃO DA DIREITA (METAS NUMÉRICAS) */}
              <div class="bg-white p-6 rounded-2xl border border-gray-100 h-fit">
                <h3 class="font-bold text-lg text-[#3B4D43] mb-1">Metas Clínicas Rápidas</h3>
                <form onSubmit={atualizarMetas} class="space-y-4 mt-4">
                  <div>
                    <label class="block text-xs font-bold uppercase text-gray-500 mb-1">Meta Calórica (kcal)</label>
                    <input type="number" value={novaMetaCalorias} onChange={(e) => setNovaMetaCalorias(e.target.value)} class="w-full bg-[#F9F6F0] border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-[#3B4D43]" required />
                  </div>
                  <div>
                    <label class="block text-xs font-bold uppercase text-gray-500 mb-1">Meta de Hidratação (ml)</label>
                    <input type="number" value={novaMetaAgua} onChange={(e) => setNovaMetaAgua(e.target.value)} class="w-full bg-[#F9F6F0] border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-[#3B4D43]" required />
                  </div>
                  <button type="submit" disabled={salvandoMeta} class="w-full bg-[#3B4D43] text-white py-3 rounded-xl font-bold text-sm shadow-sm hover:bg-[#2C3E35] transition">
                    {salvandoMeta ? "Enviando..." : "Atualizar Metas Diárias"}
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
