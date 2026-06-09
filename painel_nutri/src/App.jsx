import React, { useState, useEffect } from 'react';
import { collection, doc, onSnapshot, updateDoc, query, orderBy, limit } from 'firebase/firestore';
import { db } from './firebase';

export default function App() {
  const [pacientes, setPacientes] = useState([]);
  const [carregando, setCarregando] = useState(true);
  const [pacienteSelecionado, setPacienteSelecionado] = useState(null);
  const [dadosDiario, setDadosDiario] = useState(null);
  const [dadosConquistas, setDadosConquistas] = useState(null);
  const [historicoPesoReal, setHistoricoPesoReal] = useState([]);
  
  // 📸 ESTADOS DA ANAMNESE WEB
  const [fichaClinica, setFichaClinica] = useState({});

  const [novaMetaCalorias, setNovaMetaCalorias] = useState(2000);
  const [novaMetaAgua, setNovaMetaAgua] = useState(2500);
  const [salvandoMeta, setSalvandoMeta] = useState(false);

  const [planoCafe, setPlanoCafe] = useState("");
  const [planoAlmoco, setPlanoAlmoco] = useState("");
  const [planoLanche, setPlanoLanche] = useState("");
  const [planoJantar, setPlanoJantar] = useState("");
  const [salvandoPlano, setSalvandoPlano] = useState(false);

  const dataHoje = new Date().toISOString().split('T')[0];

  useEffect(() => {
    return onSnapshot(collection(db, 'usuarios'), (snapshot) => {
      setPacientes(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setCarregando(false);
    });
  }, []);

  useEffect(() => {
    if (!pacienteSelecionado) {
      setDadosDiario(null); setDadosConquistas(null); setHistoricoPesoReal([]);
      setPlanoCafe(""); setPlanoAlmoco(""); setPlanoLanche(""); setPlanoJantar("");
      setFichaClinica({});
      return;
    }

    // Carrega a Anamnese direto do documento do usuário
    setFichaClinica({
      idade: pacienteSelecionado.idade || "Não preenchido",
      genero: pacienteSelecionado.genero || "Não preenchido",
      altura: pacienteSelecionado.altura || "Não preenchido",
      peso_inicial: pacienteSelecionado.peso_inicial || "Não preenchido",
      hobby: pacienteSelecionado.hobby || "Não preenchido",
      objetivo: pacienteSelecionado.objetivo || "Não preenchido",
      nivel_atividade: pacienteSelecionado.nivel_atividade || "Não preenchido",
      restricao_alimentar: pacienteSelecionado.restricao_alimentar || "Nenhuma",
    });

    if (pacienteSelecionado.plano_alimentar) {
      const p = pacienteSelecionado.plano_alimentar;
      setPlanoCafe(p.cafe || ""); setPlanoAlmoco(p.almoco || ""); setPlanoLanche(p.lanche || ""); setPlanoJantar(p.jantar || "");
    }

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

    const unsubConquistas = onSnapshot(doc(db, 'usuarios', pacienteSelecionado.id, 'conquistas', dataHoje), (snapshot) => {
      setDadosConquistas(snapshot.exists() ? snapshot.data() : {});
    });

    const q = query(collection(db, 'usuarios', pacienteSelecionado.id, 'historico_peso'), orderBy('timestamp', 'asc'), limit(5));
    const unsubPesos = onSnapshot(q, (snapshot) => {
      setHistoricoPesoReal(snapshot.docs.map(doc => doc.data()));
    });

    return () => { unsubDiario(); unsubConquistas(); unsubPesos(); };
  }, [pacienteSelecionado]);

  const atualizarMetas = async (e) => {
    e.preventDefault();
    if (!pacienteSelecionado) return;
    setSalvandoMeta(true);
    try {
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id, 'diario', dataHoje), {
        meta_calorias: Number(novaMetaCalorias), meta_agua: Number(novaMetaAgua)
      });
      alert("🎯 Metas numéricas salvas!");
    } catch (e) { alert("Erro ao salvar."); }
    finally { setSalvandoMeta(false); }
  };

  const salvarPlanoAlimentar = async () => {
    if (!pacienteSelecionado) return;
    setSalvandoPlano(true);
    try {
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id), {
        plano_alimentar: { cafe: planoCafe, almoco: planoAlmoco, lanche: planoLanche, jantar: planoJantar }
      });
      alert("🍏 Cardápio Clínico sincronizado!");
    } catch (e) { alert("Erro ao salvar cardápio."); }
    finally { setSalvandoPlano(false); }
  };

  const construirCaminhoSVG = () => {
    if (historicoPesoReal.length < 2) return "";
    const larguraTotal = 500; const alturaTotal = 100;
    const pesos = historicoPesoReal.map(h => h.peso);
    const minPeso = Math.min(...pesos) - 2; const maxPeso = Math.max(...pesos) + 2;
    const deltaPeso = maxPeso - minPeso === 0 ? 1 : maxPeso - minPeso;

    return historicoPesoReal.map((h, index) => {
      const x = (index / (historicoPesoReal.length - 1)) * larguraTotal;
      const y = alturaTotal - ((h.peso - minPeso) / deltaPeso) * alturaTotal;
      return `${index === 0 ? 'M' : 'L'} ${x} ${y}`;
    }).join(' ');
  };

  return (
    <div className="flex h-screen overflow-hidden bg-[#F9F6F0]">
      <aside className="w-64 bg-[#3B4D43] text-white flex flex-col justify-between p-6">
        <div>
          <div className="flex items-center gap-3 mb-8 cursor-pointer" onClick={() => setPacienteSelecionado(null)}>
            <span className="text-2xl">🌿</span>
            <h1 className="text-xl font-bold tracking-wide">Nutri Life</h1>
          </div>
          <nav className="space-y-2">
            <button onClick={() => setPacienteSelecionado(null)} className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-medium transition text-left ${!pacienteSelecionado ? 'bg-[#2C3E35]' : 'text-white/80 hover:bg-[#2C3E35]/50'}`}>
              <span>👥</span> Pacientes
            </button>
          </nav>
        </div>
        <div className="border-t border-white/10 pt-4 text-xs text-white/60">Painel Clínico v2.5</div>
      </aside>

      <main className="flex-1 overflow-y-auto p-8 lg:p-12">
        {!pacienteSelecionado ? (
          <div>
            <header className="mb-8">
              <h2 className="text-3xl font-bold text-gray-900">Pacientes Cadastrados</h2>
              <p className="text-gray-500 text-sm mt-1">Clique em visualizar para abrir o prontuário reativo.</p>
            </header>
            <section className="bg-white rounded-2xl border border-gray-100 overflow-hidden shadow-xs">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-gray-50/70 border-b border-gray-100 text-gray-400 text-xs uppercase font-bold tracking-wider">
                    <th className="p-4 pl-6">Nome do Paciente</th>
                    <th className="p-4">ID de Registro</th>
                    <th className="p-4 text-right pr-6">Ação</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50 text-sm">
                  {carregando ? (
                    <tr><td colSpan="3" className="p-8 text-center text-gray-400">Buscando na nuvem...</td></tr>
                  ) : pacientes.length === 0 ? (
                    <tr><td colSpan="3" className="p-8 text-center text-gray-400">Nenhum paciente ativo.</td></tr>
                  ) : pacientes.map((p) => (
                    <tr key={p.id} className="hover:bg-gray-50/50 transition">
                      <td className="p-4 pl-6">
                        <p className="font-bold text-gray-900">{p.nome || "Paciente Sem Nome"}</p>
                        <p className="text-xs text-gray-400">{p.email}</p>
                      </td>
                      <td className="p-4 text-gray-400 font-mono text-xs">{p.id}</td>
                      <td className="p-4 text-right pr-6">
                        <button onClick={() => setPacienteSelecionado(p)} className="text-[#3B4D43] font-bold text-xs bg-gray-100 hover:bg-[#3B4D43] hover:text-white px-4 py-2 rounded-xl transition">Visualizar Prontuário →</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          </div>
        ) : (
          <div>
            <button onClick={() => setPacienteSelecionado(null)} className="text-sm font-bold text-[#3B4D43] hover:underline mb-4 block">← Voltar para a lista</button>
            <header className="mb-8">
              <span className="text-xs font-bold uppercase text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-md">Prontuário Completo</span>
              <h2 className="text-3xl font-bold mt-2 text-gray-900">{pacienteSelecionado.nome || "Usuário de Teste"}</h2>
            </header>

            <div className="grid grid-cols-1 xl:grid-cols-3 gap-8">
              <div className="xl:col-span-2 space-y-6">
                
                {/* 📋 CARD DA ANAMNESE PREMIUM (DADOS ENVIADOS DO CELULAR) */}
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-xs">
                  <h3 className="font-bold text-lg text-[#3B4D43] mb-4">Ficha de Anamnese & Estilo de Vida</h3>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                    <div className="bg-gray-50 p-3 rounded-xl">
                      <span className="text-xs text-gray-400 font-bold block">IDADE</span>
                      <span className="font-bold text-gray-800">{fichaClinica.idade} anos</span>
                    </div>
                    <div className="bg-gray-50 p-3 rounded-xl">
                      <span className="text-xs text-gray-400 font-bold block">GÉNERO</span>
                      <span className="font-bold text-gray-800">{fichaClinica.genero}</span>
                    </div>
                    <div className="bg-gray-50 p-3 rounded-xl">
                      <span className="text-xs text-gray-400 font-bold block">ALTURA</span>
                      <span className="font-bold text-gray-800">{fichaClinica.altura} m</span>
                    </div>
                    <div className="bg-gray-50 p-3 rounded-xl">
                      <span className="text-xs text-gray-400 font-bold block">PESO INICIAL</span>
                      <span className="font-bold text-gray-800">{fichaClinica.peso_inicial} kg</span>
                    </div>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm mt-4">
                    <div className="border border-gray-100 p-3 rounded-xl">
                      <span className="text-xs text-gray-400 font-bold block">🎯 OBJETIVO CLÍNICO</span>
                      <span className="font-medium text-gray-900">{fichaClinica.objetivo}</span>
                    </div>
                    <div className="border border-gray-100 p-3 rounded-xl">
                      <span className="text-xs text-gray-400 font-bold block">🏃 NÍVEL DE ATIVIDADE</span>
                      <span className="font-medium text-gray-900">{fichaClinica.nivel_atividade}</span>
                    </div>
                    <div className="border border-gray-100 p-3 rounded-xl">
                      <span className="text-xs text-gray-400 font-bold block">🚫 RESTRIÇÃO / ALERGIA</span>
                      <span className="font-bold text-red-600">{fichaClinica.restricao_alimentar}</span>
                    </div>
                  </div>
                  <div className="bg-emerald-50/50 p-3 rounded-xl mt-4 text-sm text-[#3B4D43]">
                    <strong>Hobby/Desporto Favorito:</strong> {fichaClinica.hobby}
                  </div>
                </div>

                <div className="bg-white p-6 rounded-2xl border border-gray-100 grid grid-cols-2 gap-4 shadow-xs">
                  <div>
                    <span className="text-xs text-gray-400 font-bold uppercase">Calorias Ingeridas Hoje</span>
                    <p className="text-2xl font-bold text-[#3B4D43] mt-1">{dadosDiario?.calorias_consumidas || 0} <span className="text-sm font-normal text-gray-400">/ {dadosDiario?.meta_calorias || 2000} kcal</span></p>
                  </div>
                  <div>
                    <span className="text-xs text-gray-400 font-bold uppercase">Água Consumida Hoje</span>
                    <p className="text-2xl font-bold text-blue-600 mt-1">{dadosDiario?.agua_consumida || 0} <span className="text-sm font-normal text-gray-400">/ {dadosDiario?.meta_agua || 2500} ml</span></p>
                  </div>
                </div>

                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-xs">
                  <h3 className="font-bold text-lg text-[#3B4D43] mb-2">Evolução do Peso</h3>
                  <div className="relative w-full h-36 bg-gray-50/50 rounded-xl p-4 flex flex-col justify-between border border-gray-100">
                    {historicoPesoReal.length < 2 ? (
                      <div className="absolute inset-0 flex items-center justify-center text-sm text-gray-400">Aguardando mais pesagens no app...</div>
                    ) : (
                      <>
                        <svg className="absolute inset-0 w-full h-full p-8" viewBox="0 0 500 100" preserveAspectRatio="none">
                          <path d={construirCaminhoSVG()} fill="none" stroke="#3B4D43" strokeWidth="3" strokeLinecap="round"/>
                        </svg>
                        <div className="flex justify-between text-[11px] text-gray-400 font-bold mt-auto pt-4 z-10">
                          {historicoPesoReal.map((h, i) => (
                            <div key={i} className="text-center">
                              <p className="text-[#3B4D43] font-extrabold">{h.peso}kg</p>
                              <p className="mt-1 font-medium text-gray-400">{h.mes}</p>
                            </div>
                          ))}
                        </div>
                      </>
                    )}
                  </div>
                </div>

                <div className="bg-white p-6 rounded-2xl border border-gray-100 space-y-4 shadow-xs">
                  <div className="flex justify-between items-center">
                    <div>
                      <h3 className="font-bold text-lg text-[#3B4D43]">Prescrever Plano Alimentar</h3>
                    </div>
                    <button onClick={salvarPlanoAlimentar} disabled={salvandoPlano} className="bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs px-4 py-2.5 rounded-xl transition">
                      {salvandoPlano ? "Salvando..." : "💾 Sincronizar Cardápio"}
                    </button>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-bold uppercase text-gray-500 mb-1">☕ Café da Manhã</label>
                      <textarea value={planoCafe} onChange={(e) => setPlanoCafe(e.target.value)} className="w-full h-24 bg-[#F9F6F0] border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] resize-none" />
                    </div>
                    <div>
                      <label className="block text-xs font-bold uppercase text-gray-500 mb-1">☀️ Almoço</label>
                      <textarea value={planoAlmoco} onChange={(e) => setPlanoAlmoco(e.target.value)} className="w-full h-24 bg-[#F9F6F0] border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] resize-none" />
                    </div>
                    <div>
                      <label className="block text-xs font-bold uppercase text-gray-500 mb-1">🍌 Lanche</label>
                      <textarea value={planoLanche} onChange={(e) => setPlanoLanche(e.target.value)} className="w-full h-24 bg-[#F9F6F0] border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] resize-none" />
                    </div>
                    <div>
                      <label className="block text-xs font-bold uppercase text-gray-500 mb-1">🌙 Jantar</label>
                      <textarea value={planoJantar} onChange={(e) => setPlanoJantar(e.target.value)} className="w-full h-24 bg-[#F9F6F0] border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] resize-none" />
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-white p-6 rounded-2xl border border-gray-100 h-fit shadow-xs">
                <h3 className="font-bold text-lg text-[#3B4D43] mb-1">Metas Rápidas</h3>
                <form onSubmit={atualizarMetas} className="space-y-4 mt-4">
                  <div>
                    <label className="block text-xs font-bold uppercase text-gray-500 mb-1">Meta Calórica (kcal)</label>
                    <input type="number" value={novaMetaCalorias} onChange={(e) => setNovaMetaCalorias(e.target.value)} className="w-full bg-[#F9F6F0] border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-[#3B4D43]" required />
                  </div>
                  <div>
                    <label className="block text-xs font-bold uppercase text-gray-500 mb-1">Meta de Hidratação (ml)</label>
                    <input type="number" value={novaMetaAgua} onChange={(e) => setNovaMetaAgua(e.target.value)} className="w-full bg-[#F9F6F0] border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-[#3B4D43]" required />
                  </div>
                  <button type="submit" disabled={salvandoMeta} className="w-full bg-[#3B4D43] text-white py-3 rounded-xl font-bold text-sm shadow-sm hover:bg-[#2C3E35] transition">
                    Atualizar Metas Diárias
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
