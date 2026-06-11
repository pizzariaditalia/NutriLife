import React, { useState, useEffect } from 'react';
import { collection, doc, onSnapshot, updateDoc, addDoc, deleteDoc, query, orderBy, limit, serverTimestamp } from 'firebase/firestore';
import { db } from './firebase';

export default function App() {
  // 📱 CONTROLES DE INTERFACE E RESPONSIVIDADE
  const [abaAtiva, setAbaAtiva] = useState('dashboard'); // dashboard, pacientes, feed, chat
  const [subAbaPaciente, setSubAbaPaciente] = useState('resumo'); // resumo, diario, metas, notas
  const [menuMobileAberto, setMenuMobileAberto] = useState(false);
  
  // 🗄️ ESTADOS DE DADOS
  const [pacientes, setPacientes] = useState([]);
  const [postsFeed, setPostsFeed] = useState([]);
  const [carregando, setCarregando] = useState(true);
  
  const [pacienteSelecionado, setPacienteSelecionado] = useState(null);
  const [dadosDiario, setDadosDiario] = useState(null);
  const [historicoPesoReal, setHistoricoPesoReal] = useState([]);
  const [fotosPaciente, setFotosPaciente] = useState({});
  const [notasInternas, setNotasInternas] = useState("");
  const [salvandoNotas, setSalvandoNotas] = useState(false);
  
  const [novaMetaCalorias, setNovaMetaCalorias] = useState(2000);
  const [novaMetaAgua, setNovaMetaAgua] = useState(2500);
  const [planoCafe, setPlanoCafe] = useState("");
  const [planoAlmoco, setPlanoAlmoco] = useState("");
  const [planoLanche, setPlanoLanche] = useState("");
  const [planoJantar, setPlanoJantar] = useState("");
  
  const [novoPostTexto, setNovoPostTexto] = useState("");
  
  const [pacienteChatSelecionado, setPacienteChatSelecionado] = useState(null);
  const [mensagensChat, setMensagensChat] = useState([]);
  const [novaMensagemTexto, setNovaMensagemTexto] = useState("");

  const dataHoje = new Date().toISOString().split('T')[0];

  // 🔄 CARREGAMENTO INICIAL
  useEffect(() => {
    const unsubPacientes = onSnapshot(collection(db, 'usuarios'), (snapshot) => {
      setPacientes(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setCarregando(false);
    });
    const unsubFeed = onSnapshot(query(collection(db, 'feed'), orderBy('timestamp', 'desc')), (snapshot) => {
      setPostsFeed(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });
    return () => { unsubPacientes(); unsubFeed(); };
  }, []);

  // 🔄 CARREGAMENTO DO PRONTUÁRIO
  useEffect(() => {
    if (!pacienteSelecionado) return;

    if (pacienteSelecionado.plano_alimentar) {
      setPlanoCafe(pacienteSelecionado.plano_alimentar.cafe || "");
      setPlanoAlmoco(pacienteSelecionado.plano_alimentar.almoco || "");
      setPlanoLanche(pacienteSelecionado.plano_alimentar.lanche || "");
      setPlanoJantar(pacienteSelecionado.plano_alimentar.jantar || "");
    }
    setNotasInternas(pacienteSelecionado.notas_nutri || "");

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

    const unsubPesos = onSnapshot(query(collection(db, 'usuarios', pacienteSelecionado.id, 'historico_peso'), orderBy('timestamp', 'asc'), limit(5)), (snapshot) => {
      setHistoricoPesoReal(snapshot.docs.map(doc => doc.data()));
    });

    const unsubFotos = onSnapshot(doc(db, 'usuarios', pacienteSelecionado.id, 'galeria', 'fotos_atuais'), (snapshot) => {
      setFotosPaciente(snapshot.exists() ? snapshot.data() : {});
    });

    return () => { unsubDiario(); unsubPesos(); unsubFotos(); };
  }, [pacienteSelecionado]);

  // 🔄 CARREGAMENTO DO CHAT
  useEffect(() => {
    if (abaAtiva === 'chat' && pacienteChatSelecionado) {
      return onSnapshot(query(collection(db, 'chats', pacienteChatSelecionado.id, 'mensagens'), orderBy('timestamp', 'asc')), (snapshot) => {
        setMensagensChat(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      });
    } else {
      setMensagensChat([]);
    }
  }, [abaAtiva, pacienteChatSelecionado]);

  // 🚀 FUNÇÕES DE AÇÃO (CRUD)
  const trocarAba = (aba) => {
    setAbaAtiva(aba);
    setMenuMobileAberto(false);
    if(aba !== 'pacientes') setPacienteSelecionado(null);
  };

  const excluirPaciente = async (id) => {
    if(window.confirm("ALERTA: Tem certeza que deseja excluir este paciente? Esta ação não pode ser desfeita.")) {
      try {
        await deleteDoc(doc(db, 'usuarios', id));
        setPacienteSelecionado(null);
        alert("Paciente excluído com sucesso.");
      } catch(e) { alert("Erro ao excluir paciente."); }
    }
  };

  const salvarPlanoEMetas = async (e) => {
    e.preventDefault();
    if (!pacienteSelecionado) return;
    try {
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id), {
        plano_alimentar: { cafe: planoCafe, almoco: planoAlmoco, lanche: planoLanche, jantar: planoJantar }
      });
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id, 'diario', dataHoje), {
        meta_calorias: Number(novaMetaCalorias), meta_agua: Number(novaMetaAgua)
      });
      alert("✅ Cardápio e Metas Sincronizados com o Celular do Paciente!");
    } catch (e) { alert("Erro ao salvar."); }
  };

  const salvarNotas = async () => {
    setSalvandoNotas(true);
    try {
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id), { notas_nutri: notasInternas });
      alert("✅ Notas privadas salvas!");
    } catch(e) { alert("Erro ao salvar notas."); }
    finally { setSalvandoNotas(false); }
  };

  const publicarNoFeed = async (e) => {
    e.preventDefault();
    if (novoPostTexto.trim() === "") return;
    try {
      await addDoc(collection(db, 'feed'), { autor: "Nutricionista Oficial 👑", texto: novoPostTexto.trim(), curtidas: [], timestamp: serverTimestamp() });
      setNovoPostTexto("");
    } catch (err) { alert("Erro ao publicar."); }
  };

  const excluirPost = async (id) => {
    if(window.confirm("Deseja apagar esta publicação do Feed de todos os pacientes?")) {
      await deleteDoc(doc(db, 'feed', id));
    }
  };

  const enviarMensagemChat = async (e) => {
    e.preventDefault();
    if (novaMensagemTexto.trim() === "" || !pacienteChatSelecionado) return;
    await addDoc(collection(db, 'chats', pacienteChatSelecionado.id, 'mensagens'), { texto: novaMensagemTexto.trim(), remetente: 'nutri', timestamp: serverTimestamp() });
    setNovaMensagemTexto("");
  };

  // 📊 GRÁFICO SVG
  const construirCaminhoSVG = () => {
    if (historicoPesoReal.length < 2) return "";
    const larguraTotal = 1000; const alturaTotal = 100;
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
    <div className="flex h-screen overflow-hidden bg-[#F9F6F0] flex-col md:flex-row">
      
      {/* 📱 HEADER MOBILE */}
      <div className="md:hidden bg-[#3B4D43] text-white p-4 flex justify-between items-center z-50 shadow-md">
        <div className="flex items-center gap-2"><span className="text-xl">🌿</span><h1 className="font-bold">Nutri Life Pro</h1></div>
        <button onClick={() => setMenuMobileAberto(!menuMobileAberto)} className="p-2 text-2xl focus:outline-none">☰</button>
      </div>

      {/* 🧭 SIDEBAR RESPONSIVA */}
      <aside className={`${menuMobileAberto ? 'translate-x-0' : '-translate-x-full'} md:translate-x-0 fixed md:relative z-40 w-64 h-full bg-[#3B4D43] text-white flex flex-col justify-between p-6 shrink-0 transition-transform duration-300 ease-in-out`}>
        <div>
          <div className="hidden md:flex items-center gap-3 mb-8">
            <span className="text-3xl">🌿</span>
            <h1 className="text-2xl font-bold tracking-wide">Nutri Life</h1>
          </div>
          <nav className="space-y-2">
            <button onClick={() => trocarAba('dashboard')} className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-medium transition text-left ${abaAtiva === 'dashboard' ? 'bg-[#2C3E35] font-bold' : 'text-white/80 hover:bg-[#2C3E35]/50'}`}>📊 Visão Geral</button>
            <button onClick={() => trocarAba('pacientes')} className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-medium transition text-left ${abaAtiva === 'pacientes' ? 'bg-[#2C3E35] font-bold' : 'text-white/80 hover:bg-[#2C3E35]/50'}`}>👥 Pacientes</button>
            <button onClick={() => trocarAba('feed')} className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-medium transition text-left ${abaAtiva === 'feed' ? 'bg-[#2C3E35] font-bold' : 'text-white/80 hover:bg-[#2C3E35]/50'}`}>📣 Gestão do Feed</button>
            <button onClick={() => trocarAba('chat')} className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-medium transition text-left ${abaAtiva === 'chat' ? 'bg-[#2C3E35] font-bold' : 'text-white/80 hover:bg-[#2C3E35]/50'}`}>💬 Consultório Web</button>
          </nav>
        </div>
        <div className="border-t border-white/10 pt-4 text-xs text-white/60">Versão Web Responsiva</div>
      </aside>

      {/* 🖥️ ÁREA CENTRAL DE TRABALHO */}
      <main className="flex-1 overflow-y-auto p-4 md:p-8 lg:p-10 w-full relative">
        
        {/* 📊 ABA 0: DASHBOARD / VISÃO GERAL */}
        {abaAtiva === 'dashboard' && (
          <div className="animate-fade-in">
            <header className="mb-8">
              <h2 className="text-2xl md:text-3xl font-bold text-gray-900">Bom dia, Nutri! ☀️</h2>
              <p className="text-gray-500 text-sm mt-1">Aqui está o resumo do seu ecossistema hoje.</p>
            </header>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4">
                <div className="bg-emerald-100 p-4 rounded-full text-emerald-600 text-2xl">👥</div>
                <div><p className="text-gray-500 text-xs font-bold uppercase">Pacientes Ativos</p><p className="text-3xl font-bold text-gray-900">{pacientes.length}</p></div>
              </div>
              <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4">
                <div className="bg-blue-100 p-4 rounded-full text-blue-600 text-2xl">📣</div>
                <div><p className="text-gray-500 text-xs font-bold uppercase">Publicações no Feed</p><p className="text-3xl font-bold text-gray-900">{postsFeed.length}</p></div>
              </div>
              <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-4">
                <div className="bg-orange-100 p-4 rounded-full text-orange-600 text-2xl">🔥</div>
                <div><p className="text-gray-500 text-xs font-bold uppercase">Sistema Operacional</p><p className="text-lg font-bold text-gray-900 text-green-600">Online & Sincronizado</p></div>
              </div>
            </div>
          </div>
        )}

        {/* 👥 ABA 1: PACIENTES E PRONTUÁRIOS */}
        {abaAtiva === 'pacientes' && (!pacienteSelecionado ? (
          <div className="animate-fade-in">
            <header className="mb-6"><h2 className="text-2xl md:text-3xl font-bold text-gray-900">Meus Pacientes</h2></header>
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-x-auto">
              <table className="w-full text-left min-w-[600px]">
                <thead><tr className="bg-gray-50 text-gray-400 text-xs uppercase font-bold border-b border-gray-100"><th className="p-4 pl-6">Paciente</th><th className="p-4">Objetivo</th><th className="p-4 text-right pr-6">Ação</th></tr></thead>
                <tbody className="divide-y divide-gray-50 text-sm">
                  {carregando ? <tr><td colSpan="3" className="p-8 text-center text-gray-400">Carregando...</td></tr> : 
                   pacientes.length === 0 ? <tr><td colSpan="3" className="p-8 text-center text-gray-400">Nenhum paciente cadastrado.</td></tr> : 
                   pacientes.map((p) => (
                    <tr key={p.id} className="hover:bg-gray-50 transition">
                      <td className="p-4 pl-6"><p className="font-bold text-gray-900">{p.nome || "Sem Nome"}</p><p className="text-xs text-gray-400">{p.email}</p></td>
                      <td className="p-4"><span className="bg-gray-100 text-gray-600 px-2 py-1 rounded-md text-xs font-bold">{p.objetivo || 'Não definido'}</span></td>
                      <td className="p-4 text-right pr-6"><button onClick={() => {setPacienteSelecionado(p); setSubAbaPaciente('resumo');}} className="text-[#3B4D43] font-bold text-xs bg-emerald-50 hover:bg-[#3B4D43] hover:text-white px-4 py-2 rounded-xl transition">Abrir Prontuário</button></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        ) : (
          <div className="animate-fade-in">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4">
              <div>
                <button onClick={() => setPacienteSelecionado(null)} className="text-sm font-bold text-[#3B4D43] hover:underline mb-2 block">← Voltar à lista</button>
                <h2 className="text-2xl md:text-3xl font-bold text-gray-900">{pacienteSelecionado.nome}</h2>
                <p className="text-xs text-gray-500 font-mono mt-1">ID: {pacienteSelecionado.id}</p>
              </div>
              <button onClick={() => excluirPaciente(pacienteSelecionado.id)} className="bg-red-50 text-red-600 border border-red-100 hover:bg-red-600 hover:text-white font-bold text-xs px-4 py-2 rounded-xl transition">🗑️ Excluir Paciente</button>
            </div>

            {/* NAVEGAÇÃO INTERNA DO PACIENTE (BOTOES RESPONSIVOS) */}
            <div className="flex overflow-x-auto gap-2 mb-6 pb-2 hide-scrollbar">
              {['resumo', 'diario', 'metas', 'notas'].map(aba => (
                <button key={aba} onClick={() => setSubAbaPaciente(aba)} className={`whitespace-nowrap px-4 py-2 rounded-xl text-sm font-bold transition border ${subAbaPaciente === aba ? 'bg-[#3B4D43] text-white border-[#3B4D43]' : 'bg-white text-gray-500 border-gray-200 hover:bg-gray-50'}`}>
                  {aba === 'resumo' && '📋 Resumo Clínico'} {aba === 'diario' && '🍽️ Diário & Fotos'} {aba === 'metas' && '🎯 Cardápio & Metas'} {aba === 'notas' && '🔒 Notas Privadas'}
                </button>
              ))}
            </div>

            {/* CONTEÚDOS DAS SUB-ABAS */}
            {subAbaPaciente === 'resumo' && (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
                  <h3 className="font-bold text-lg text-gray-800 mb-4">Anamnese do App</h3>
                  <div className="grid grid-cols-2 gap-4 text-sm mb-4">
                    <div className="bg-gray-50 p-3 rounded-xl"><span className="text-[10px] text-gray-400 font-bold block">IDADE / GÊNERO</span><span className="font-bold">{fichaClinica.idade}a • {fichaClinica.genero}</span></div>
                    <div className="bg-gray-50 p-3 rounded-xl"><span className="text-[10px] text-gray-400 font-bold block">ALTURA / PESO INICIAL</span><span className="font-bold">{fichaClinica.altura}m • {fichaClinica.peso_inicial}kg</span></div>
                  </div>
                  <div className="border border-gray-100 p-3 rounded-xl mb-4"><span className="text-[10px] text-gray-400 font-bold block">OBJETIVO & ATIVIDADE</span><span className="font-bold block text-gray-800">{fichaClinica.objetivo} • {fichaClinica.nivel_atividade}</span></div>
                  <div className="bg-red-50 p-3 rounded-xl text-red-700 text-sm"><span className="text-[10px] text-red-400 font-bold block uppercase">Restrições e Alergias</span><strong>{fichaClinica.restricao_alimentar}</strong></div>
                </div>
                
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col">
                  <h3 className="font-bold text-lg text-gray-800 mb-4">Evolução de Peso (Gráfico)</h3>
                  <div className="relative w-full flex-1 min-h-[150px] bg-gray-50/50 rounded-xl p-4 border border-gray-100 flex flex-col justify-end">
                    {historicoPesoReal.length < 2 ? <p className="text-sm text-gray-400 m-auto">Poucos dados.</p> : (
                      <>
                        <svg className="absolute inset-0 w-full h-full p-4" viewBox="0 0 1000 100" preserveAspectRatio="none"><path d={construirCaminhoSVG()} fill="none" stroke="#3B4D43" strokeWidth="4" strokeLinecap="round"/></svg>
                        <div className="flex justify-between text-[10px] text-gray-400 font-bold z-10 w-full">
                          {historicoPesoReal.map((h, i) => <div key={i} className="text-center"><p className="text-gray-800">{h.peso}kg</p><p>{h.data ? h.data.split('-').slice(1).reverse().join('/') : ''}</p></div>)}
                        </div>
                      </>
                    )}
                  </div>
                </div>
              </div>
            )}

            {subAbaPaciente === 'diario' && (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
                  <h3 className="font-bold text-lg text-gray-800 mb-4">Diário de Hoje (Consumo Real)</h3>
                  <div className="flex gap-4 mb-6">
                    <div className="flex-1 bg-emerald-50 p-4 rounded-xl text-center"><p className="text-xs font-bold text-emerald-600 uppercase">Calorias</p><p className="text-2xl font-bold text-gray-800">{dadosDiario?.calorias_consumidas || 0}</p></div>
                    <div className="flex-1 bg-blue-50 p-4 rounded-xl text-center"><p className="text-xs font-bold text-blue-600 uppercase">Água (ml)</p><p className="text-2xl font-bold text-gray-800">{dadosDiario?.agua_consumida || 0}</p></div>
                  </div>
                  <h4 className="text-xs font-bold text-gray-400 uppercase mb-2">Alimentos Registrados</h4>
                  <ul className="space-y-2 max-h-[300px] overflow-y-auto pr-2">
                    {(!dadosDiario?.historico_alimentos || dadosDiario.historico_alimentos.length === 0) ? <p className="text-sm text-gray-400 italic">Nada registrado hoje.</p> : 
                      dadosDiario.historico_alimentos.map((item, idx) => (
                        <li key={idx} className="flex justify-between items-center p-3 bg-gray-50 rounded-xl text-sm border border-gray-100">
                          <div><p className="font-bold text-gray-800">{item.nome}</p><p className="text-[10px] text-gray-500 uppercase">{item.turno} • {item.quantidade}x {item.medida_escolhida}</p></div>
                          <span className="font-bold text-emerald-600">{item.calorias} kcal</span>
                        </li>
                      ))
                    }
                  </ul>
                </div>
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
                  <h3 className="font-bold text-lg text-gray-800 mb-4">Galeria de Evolução Física</h3>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <p className="text-xs font-bold text-gray-400 uppercase">Antes</p>
                      <div className="aspect-square bg-gray-100 rounded-xl bg-cover bg-center" style={{backgroundImage: `url(${fotosPaciente.antes_1 || ''})`}}>{!fotosPaciente.antes_1 && <span className="flex items-center justify-center h-full text-gray-300 text-xs">Vazio</span>}</div>
                    </div>
                    <div className="space-y-2">
                      <p className="text-xs font-bold text-gray-400 uppercase">Atual</p>
                      <div className="aspect-square bg-gray-100 rounded-xl bg-cover bg-center" style={{backgroundImage: `url(${fotosPaciente.depois_1 || ''})`}}>{!fotosPaciente.depois_1 && <span className="flex items-center justify-center h-full text-gray-300 text-xs">Vazio</span>}</div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {subAbaPaciente === 'metas' && (
              <form onSubmit={salvarPlanoEMetas} className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
                <h3 className="font-bold text-lg text-gray-800 mb-6">Prescrever Cardápio & Metas Diárias</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                  <div><label className="block text-xs font-bold text-gray-500 mb-2">Meta Calórica (kcal/dia)</label><input type="number" value={novaMetaCalorias} onChange={(e)=>setNovaMetaCalorias(e.target.value)} className="w-full bg-gray-50 border border-gray-200 rounded-xl p-3" /></div>
                  <div><label className="block text-xs font-bold text-gray-500 mb-2">Meta de Água (ml/dia)</label><input type="number" value={novaMetaAgua} onChange={(e)=>setNovaMetaAgua(e.target.value)} className="w-full bg-gray-50 border border-gray-200 rounded-xl p-3" /></div>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                  <div><label className="block text-xs font-bold text-gray-500 mb-2">☕ Café da Manhã</label><textarea value={planoCafe} onChange={(e)=>setPlanoCafe(e.target.value)} className="w-full h-24 bg-gray-50 border border-gray-200 rounded-xl p-3 resize-none" /></div>
                  <div><label className="block text-xs font-bold text-gray-500 mb-2">☀️ Almoço</label><textarea value={planoAlmoco} onChange={(e)=>setPlanoAlmoco(e.target.value)} className="w-full h-24 bg-gray-50 border border-gray-200 rounded-xl p-3 resize-none" /></div>
                  <div><label className="block text-xs font-bold text-gray-500 mb-2">🍌 Lanche</label><textarea value={planoLanche} onChange={(e)=>setPlanoLanche(e.target.value)} className="w-full h-24 bg-gray-50 border border-gray-200 rounded-xl p-3 resize-none" /></div>
                  <div><label className="block text-xs font-bold text-gray-500 mb-2">🌙 Jantar</label><textarea value={planoJantar} onChange={(e)=>setPlanoJantar(e.target.value)} className="w-full h-24 bg-gray-50 border border-gray-200 rounded-xl p-3 resize-none" /></div>
                </div>
                <button type="submit" className="w-full md:w-auto bg-[#3B4D43] text-white font-bold px-8 py-3 rounded-xl hover:bg-[#2C3E35] transition">💾 Salvar e Sincronizar com Paciente</button>
              </form>
            )}

            {subAbaPaciente === 'notas' && (
              <div className="bg-yellow-50 p-6 rounded-2xl border border-yellow-100 shadow-sm">
                <h3 className="font-bold text-lg text-yellow-800 mb-2">Bloco de Notas Privado 🔒</h3>
                <p className="text-sm text-yellow-700 mb-4">Apenas você tem acesso a estas anotações. O paciente não vê isto no aplicativo.</p>
                <textarea value={notasInternas} onChange={(e) => setNotasInternas(e.target.value)} placeholder="Ex: Paciente relatou insônia, ajustar magnésio na próxima consulta..." className="w-full h-48 bg-white border border-yellow-200 rounded-xl p-4 text-sm focus:outline-yellow-500 resize-none mb-4 shadow-inner" />
                <button onClick={salvarNotas} disabled={salvandoNotas} className="bg-yellow-600 text-white font-bold px-6 py-2.5 rounded-xl hover:bg-yellow-700 transition">{salvandoNotas ? 'Salvando...' : 'Guardar Anotações'}</button>
              </div>
            )}
          </div>
        )}

        {/* 📣 ABA 2: FEED GLOBAL */}
        {abaAtiva === 'feed' && (
          <div className="max-w-4xl mx-auto animate-fade-in">
            <header className="mb-6"><h2 className="text-2xl md:text-3xl font-bold text-gray-900">Gestão do Feed</h2></header>
            <form onSubmit={publicarNoFeed} className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm mb-8">
              <textarea value={novoPostTexto} onChange={(e) => setNovoPostTexto(e.target.value)} placeholder="Escreva uma dica, aviso ou motivação para todos os pacientes..." className="w-full h-28 bg-gray-50 border border-gray-200 rounded-xl p-4 text-sm focus:outline-[#3B4D43] resize-none mb-4" />
              <button type="submit" className="w-full md:w-auto float-right bg-[#3B4D43] text-white font-bold text-sm px-6 py-3 rounded-xl hover:bg-[#2C3E35] transition">📣 Publicar no App</button>
              <div className="clear-both"></div>
            </form>
            <div className="space-y-4">
              {postsFeed.map(post => (
                <div key={post.id} className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm relative group">
                  <div className="flex justify-between items-start mb-2">
                    <span className="text-xs text-gray-400 font-bold">{post.autor}</span>
                    <button onClick={() => excluirPost(post.id)} className="text-red-500 opacity-0 group-hover:opacity-100 transition text-xs font-bold hover:underline">Apagar Post</button>
                  </div>
                  <p className="text-sm text-gray-800 leading-relaxed mb-4">{post.texto}</p>
                  <div className="border-t border-gray-100 pt-3 text-xs text-gray-400 font-bold">❤️ {post.curtidas?.length || 0} Pacientes curtiram</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* 💬 ABA 3: CHAT VIRTUAL */}
        {abaAtiva === 'chat' && (
          <div className="h-[calc(100vh-8rem)] flex flex-col md:flex-row gap-4 md:gap-6 animate-fade-in">
            <div className={`w-full md:w-80 bg-white border border-gray-100 rounded-2xl p-4 overflow-y-auto shadow-sm flex-col ${pacienteChatSelecionado ? 'hidden md:flex' : 'flex'}`}>
              <h3 className="font-bold text-md text-gray-900 mb-4 px-2">Canais de Atendimento</h3>
              {pacientes.map(p => (
                <button key={p.id} onClick={() => setPacienteChatSelecionado(p)} className={`w-full text-left p-3 rounded-xl transition flex flex-col mb-2 border ${pacienteChatSelecionado?.id === p.id ? 'bg-[#3B4D43] border-[#3B4D43] text-white' : 'bg-white border-gray-100 hover:bg-gray-50 text-gray-700'}`}>
                  <span className="font-bold text-sm">{p.nome || "Sem Nome"}</span><span className={`text-xs mt-0.5 ${pacienteChatSelecionado?.id === p.id ? 'text-white/60' : 'text-gray-400'}`}>Abrir chat</span>
                </button>
              ))}
            </div>
            
            <div className={`flex-1 bg-white border border-gray-100 rounded-2xl flex-col justify-between overflow-hidden shadow-sm ${pacienteChatSelecionado ? 'flex' : 'hidden md:flex'}`}>
              {pacienteChatSelecionado ? (
                <>
                  <header className="p-4 border-b border-gray-100 bg-gray-50 flex items-center gap-3">
                    <button onClick={() => setPacienteChatSelecionado(null)} className="md:hidden text-gray-500 font-bold">←</button>
                    <h4 className="font-bold text-gray-900 text-sm">Conversando com {pacienteChatSelecionado.nome}</h4>
                  </header>
                  <div className="flex-1 p-4 overflow-y-auto bg-gray-50/50 space-y-4">
                    {mensagensChat.map(m => {
                      const souEu = m.remetente === 'nutri';
                      return (
                        <div key={m.id} className={`flex ${souEu ? 'justify-end' : 'justify-start'}`}>
                          <div className={`max-w-[85%] md:max-w-[70%] p-3 rounded-2xl text-sm shadow-sm ${souEu ? 'bg-[#3B4D43] text-white rounded-br-none' : 'bg-white text-gray-800 border border-gray-100 rounded-bl-none'}`}>{m.texto}</div>
                        </div>
                      );
                    })}
                  </div>
                  <form onSubmit={enviarMensagemChat} className="p-3 border-t border-gray-100 bg-white flex gap-2">
                    <input type="text" value={novaMensagemTexto} onChange={(e) => setNovaMensagemTexto(e.target.value)} placeholder="Digite sua resposta..." className="flex-1 bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-[#3B4D43]" />
                    <button type="submit" className="bg-[#3B4D43] text-white font-bold px-6 py-3 rounded-xl hover:bg-[#2C3E35] transition">Enviar</button>
                  </form>
                </>
              ) : (
                <div className="flex-1 flex flex-col items-center justify-center p-8 text-gray-400"><span className="text-5xl mb-4">💬</span><p className="text-sm font-medium">Selecione um paciente ao lado para iniciar o atendimento.</p></div>
              )}
            </div>
          </div>
        )}

      </main>
    </div>
  );
}
