import React, { useState, useEffect } from 'react';
import { collection, doc, onSnapshot, updateDoc } from 'firebase/firestore';
import { db } from './firebase';

export default function App() {
  const [pacientes, setPacientes] = useState([]);
  const [carregando, setCarregando] = useState(true);
  const [pacienteSelecionado, setPacienteSelecionado] = useState(null);
  const [dadosDiario, setDadosDiario] = useState(null);

  // Estados para o formulário de alteração de metas
  const [novaMetaCalorias, setNovaMetaCalorias] = useState(2000);
  const [novaMetaAgua, setNovaMetaAgua] = useState(2500);
  const [salvandoMeta, setSalvandoMeta] = useState(false);

  // Retorna a chave de data de hoje "AAAA-MM-DD" para cruzar os dados com o app mobile
  const getTodayDateKey = () => {
    const agora = new Date();
    const ano = agora.getFullYear();
    const mes = String(agora.getMonth() + 1).padStart(2, '0');
    const dia = String(agora.getDate()).padStart(2, '0');
    return `${ano}-${mes}-${dia}`;
  };

  const dataHoje = getTodayDateKey();

  // 📡 ESCUTADOR 1: Lista de pacientes em tempo real
  useEffect(() => {
    const colecaoRef = collection(db, 'usuarios');
    const fecharConexao = onSnapshot(colecaoRef, (snapshot) => {
      const lista = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setPacientes(lista);
      setCarregando(false);
    });
    return () => fecharConexao();
  }, []);

  // 📡 ESCUTADOR 2: Diário específico do paciente selecionado (Tempo Real)
  useEffect(() => {
    if (!pacienteSelecionado) {
      setDadosDiario(null);
      return;
    }

    const diarioDocRef = doc(db, 'usuarios', pacienteSelecionado.id, 'diario', dataHoje);
    const fecharConexaoDiario = onSnapshot(diarioDocRef, (snapshot) => {
      if (snapshot.exists()) {
        const dados = snapshot.data();
        setDadosDiario(dados);
        setNovaMetaCalorias(dados.meta_calorias || 2000);
        setNovaMetaAgua(dados.meta_agua || 2500);
      } else {
        // Se o paciente ainda não abriu o app hoje, criamos um estado zerado na tela
        setDadosDiario({
          calorias_consumidas: 0,
          meta_calorias: 2000,
          agua_consumida: 0,
          meta_agua: 2500,
          historico_alimentos: []
        });
        setNovaMetaCalorias(2000);
        setNovaMetaAgua(2500);
      }
    });

    return () => fecharConexaoDiario();
  }, [pacienteSelecionado]);

  // 🔥 GRAVAÇÃO NA NUVEM: Atualiza as metas do paciente e reflete no celular dele na hora!
  const atualizarMetasNoFirebase = async (e) => {
    e.preventDefault();
    if (!pacienteSelecionado) return;

    setSalvandoMeta(true);
    try {
      const diarioDocRef = doc(db, 'usuarios', pacienteSelecionado.id, 'diario', dataHoje);
      await updateDoc(diarioDocRef, {
        meta_calorias: Number(novaMetaCalorias),
        meta_agua: Number(novaMetaAgua)
      });
      alert("🎯 Metas atualizadas com sucesso! O celular do paciente já foi atualizado.");
    } catch (erro) {
      console.error("Erro ao atualizar metas:", erro);
      alert("Erro ao salvar. Verifique se o paciente já realizou o primeiro acesso hoje.");
    } finally {
      setSalvandoMeta(false);
    }
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
        <div class="border-t border-white/10 pt-4 text-xs text-white/60">
          Painel Clínico v1.2
        </div>
      </aside>

      <main class="flex-1 overflow-y-auto p-8 lg:p-12">
        
        {/* TELA 1: LISTAGEM GERAL DE PACIENTES */}
        {!pacienteSelecionado ? (
          <div>
            <header class="mb-8">
              <h2 class="text-3xl font-bold">Pacientes Cadastrados</h2>
              <p class="text-gray-500 text-sm mt-1">Clique em um paciente para gerenciar a dieta e ver o diário ao vivo.</p>
            </header>

            <section class="bg-white rounded-2xl shadow-xs border border-gray-100 overflow-hidden">
              <div class="overflow-x-auto">
                {carregando ? (
                  <div class="p-8 text-center text-gray-400">Carregando pacientes da nuvem...</div>
                ) : pacientes.length === 0 ? (
                  <div class="p-8 text-center text-gray-400">Nenhum paciente realizou o cadastro no aplicativo celular ainda.</div>
                ) : (
                  <table class="w-full text-left border-collapse">
                    <thead>
                      <tr class="bg-gray-50/70 border-b border-gray-100 text-gray-400 text-xs uppercase font-bold tracking-wider">
                        <th class="p-4 pl-6">Nome do Paciente</th>
                        <th class="p-4">Identificador Único</th>
                        <th class="p-4 text-right pr-6">Ação</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-50 text-sm">
                      {pacientes.map((paciente) => (
                        <tr key={paciente.id} class="hover:bg-gray-50/50 transition">
                          <td class="p-4 pl-6">
                            <p class="font-bold text-gray-900">{paciente.nome || "Usuário de Teste"}</p>
                            <p class="text-xs text-gray-400">{paciente.email || "Sem e-mail"}</p>
                          </td>
                          <td class="p-4 text-gray-400 font-mono text-xs">{paciente.id}</td>
                          <td class="p-4 text-right pr-6">
                            <button onClick={() => setPacienteSelecionado(paciente)} class="text-[#3B4D43] font-bold text-xs bg-gray-100 hover:bg-[#3B4D43] hover:text-white px-4 py-2 rounded-xl transition">
                              Visualizar Diário →
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            </section>
          </div>
        ) : (
          
          /* TELA 2: ÁREA DE TRABALHO DA DIETA DO PACIENTE (DETALHES) */
          <div>
            <button onClick={() => setPacienteSelecionado(null)} class="text-sm font-bold text-[#3B4D43] hover:underline mb-4 block">
              ← Voltar para a lista
            </button>
            
            <header class="mb-8 flex flex-col md:flex-row md:justify-between md:items-center gap-4">
              <div>
                <span class="text-xs font-bold uppercase text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-md">Prontuário Ativo</span>
                <h2 class="text-3xl font-bold mt-2">{pacienteSelecionado.nome || "Usuário de Teste"}</h2>
                <p class="text-gray-500 text-sm">{pacienteSelecionado.email}</p>
              </div>
            </header>

            <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
              
              {/* COLUNA 1 & 2: MONITOR DE ALIMENTAÇÃO DO CELULAR */}
              <div class="lg:col-span-2 space-y-6">
                
                {/* STATUS DE HOJE */}
                <div class="bg-white p-6 rounded-2xl border border-gray-100 grid grid-cols-2 gap-4">
                  <div>
                    <span class="text-xs text-gray-400 font-bold uppercase">Calorias Consumidas</span>
                    <p class="text-2xl font-bold text-[#3B4D43] mt-1">
                      {dadosDiario ? dadosDiario.calorias_consumidas : 0} <span class="text-sm font-normal text-gray-400">/ {dadosDiario ? dadosDiario.meta_calorias : 2000} kcal</span>
                    </p>
                  </div>
                  <div>
                    <span class="text-xs text-gray-400 font-bold uppercase">Água Ingerida</span>
                    <p class="text-2xl font-bold text-blue-600 mt-1">
                      {dadosDiario ? dadosDiario.agua_consumida : 0} <span class="text-sm font-normal text-gray-400">/ {dadosDiario ? dadosDiario.meta_agua : 2500} ml</span>
                    </p>
                  </div>
                </div>

                {/* HISTÓRICO DE REFEIÇÕES DO DIA */}
                <div class="bg-white rounded-2xl border border-gray-100 p-6">
                  <h3 class="font-bold text-lg mb-4 text-[#3B4D43]">Refeições Registradas Hoje</h3>
                  
                  {!dadosDiario || !dadosDiario.historico_alimentos || dadosDiario.historico_alimentos.length === 0 ? (
                    <p class="text-gray-400 text-sm text-center py-8">Nenhum alimento lançado no diário hoje por este paciente.</p>
                  ) : (
                    <div class="divide-y divide-gray-100">
                      {dadosDiario.historico_alimentos.map((alimento, i) => (
                        <div key={i} class="py-3 flex justify-between items-center text-sm">
                          <div>
                            <p class="font-semibold text-gray-950">{alimento.nome}</p>
                            <p class="text-xs text-gray-400">Turno: <span class="font-medium text-gray-600">{alimento.turno}</span> • Qtd: {alimento.quantidade}x</p>
                          </div>
                          <span class="font-bold text-[#3B4D43]">{alimento.calorias} kcal</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              {/* COLUNA 3: PAINEL DE ALTERAÇÃO DE METAS (PRESCRIÇÃO) */}
              <div class="bg-white p-6 rounded-2xl border border-gray-100 h-fit">
                <h3 class="font-bold text-lg text-[#3B4D43] mb-1">Prescrever Novas Metas</h3>
                <p class="text-xs text-gray-400 mb-6">Altere os alvos diários abaixo para reconfigurar os gráficos do app do paciente.</p>
                
                <form onSubmit={atualizarMetasNoFirebase} class="space-y-4">
                  <div>
                    <label class="block text-xs font-bold uppercase text-gray-500 mb-1">Meta de Calorias (kcal)</label>
                    <input type="number" value={novaMetaCalorias} onChange={(e) => setNovaMetaCalorias(e.target.value)} class="w-full bg-[#F9F6F0] border border-gray-200 rounded-xl px-4 py-2.5 text-sm font-medium focus:outline-[#3B4D43]" required />
                  </div>
                  <div>
                    <label class="block text-xs font-bold uppercase text-gray-500 mb-1">Meta de Hidratação (ml)</label>
                    <input type="number" value={novaMetaAgua} onChange={(e) => setNovaMetaAgua(e.target.value)} class="w-full bg-[#F9F6F0] border border-gray-200 rounded-xl px-4 py-2.5 text-sm font-medium focus:outline-[#3B4D43]" required />
                  </div>
                  <button type="submit" disabled={salvandoMeta} class="w-full bg-[#3B4D43] text-white py-3 rounded-xl font-bold text-sm shadow-sm hover:bg-[#2C3E35] transition disabled:opacity-50 mt-2">
                    {salvandoMeta ? "Salvando na Nuvem..." : "Salvar e Enviar Pro Celular"}
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
