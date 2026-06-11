import React, { useState, useEffect } from 'react';
import { collection, doc, onSnapshot, updateDoc, addDoc, deleteDoc, query, orderBy, limit, serverTimestamp } from 'firebase/firestore';
import { db } from './firebase';

// ==========================================
// 🎨 ÍCONES VETORIAIS PROFISSIONAIS (SVG)
// ==========================================
const IconLayout = () => <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>;
const IconUsers = () => <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>;
const IconMegaphone = () => <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 11 18-5v12L3 14v-3z"/><path d="M11.6 16.8a3 3 0 1 1-5.8-1.6"/></svg>;
const IconMessage = () => <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m3 21 1.9-5.7a8.5 8.5 0 1 1 3.8 3.8z"/></svg>;
const IconMenu = () => <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="18" y2="18"/></svg>;
const IconX = () => <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>;
const IconArrowRight = () => <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>;
const IconTrash = () => <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>;
const IconLeaf = () => <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/></svg>;

// ==========================================
// 🚀 COMPONENTE PRINCIPAL
// ==========================================
export default function App() {
  const [abaAtiva, setAbaAtiva] = useState('dashboard'); 
  const [subAbaPaciente, setSubAbaPaciente] = useState('resumo'); 
  const [menuMobileAberto, setMenuMobileAberto] = useState(false);
  
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

  useEffect(() => {
    if (abaAtiva === 'chat' && pacienteChatSelecionado) {
      return onSnapshot(query(collection(db, 'chats', pacienteChatSelecionado.id, 'mensagens'), orderBy('timestamp', 'asc')), (snapshot) => {
        setMensagensChat(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      });
    } else {
      setMensagensChat([]);
    }
  }, [abaAtiva, pacienteChatSelecionado]);

  const trocarAba = (aba) => {
    setAbaAtiva(aba);
    setMenuMobileAberto(false);
    if(aba !== 'pacientes') setPacienteSelecionado(null);
  };

  const excluirPaciente = async (id) => {
    if(window.confirm("ALERTA: Tem certeza que deseja excluir este paciente?")) {
      try {
        await deleteDoc(doc(db, 'usuarios', id));
        setPacienteSelecionado(null);
      } catch(e) { alert("Erro ao excluir paciente."); }
    }
  };

  const salvarPlanoEMetas = async (e) => {
    e.preventDefault();
    if (!pacienteSelecionado) return;
    try {
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id), { plano_alimentar: { cafe: planoCafe, almoco: planoAlmoco, lanche: planoLanche, jantar: planoJantar } });
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id, 'diario', dataHoje), { meta_calorias: Number(novaMetaCalorias), meta_agua: Number(novaMetaAgua) });
      alert("Sucesso! Cardápio e metas sincronizados.");
    } catch (e) { alert("Erro ao salvar."); }
  };

  const salvarNotas = async () => {
    setSalvandoNotas(true);
    try {
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id), { notas_nutri: notasInternas });
    } catch(e) { alert("Erro ao salvar notas."); }
    finally { setSalvandoNotas(false); }
  };

  const publicarNoFeed = async (e) => {
    e.preventDefault();
    if (novoPostTexto.trim() === "") return;
    try {
      await addDoc(collection(db, 'feed'), { autor: "Nutricionista Oficial", texto: novoPostTexto.trim(), curtidas: [], timestamp: serverTimestamp() });
      setNovoPostTexto("");
    } catch (err) { alert("Erro ao publicar."); }
  };

  const excluirPost = async (id) => {
    if(window.confirm("Apagar esta publicação do Feed?")) {
      await deleteDoc(doc(db, 'feed', id));
    }
  };

  const enviarMensagemChat = async (e) => {
    e.preventDefault();
    if (novaMensagemTexto.trim() === "" || !pacienteChatSelecionado) return;
    await addDoc(collection(db, 'chats', pacienteChatSelecionado.id, 'mensagens'), { texto: novaMensagemTexto.trim(), remetente: 'nutri', timestamp: serverTimestamp() });
    setNovaMensagemTexto("");
  };

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
    <div className="flex h-screen overflow-hidden bg-[#F9F6F0] font-sans text-gray-800 relative">
      
      {/* 🛡️ OVERLAY MOBILE (Fecha o menu ao clicar fora) */}
      {menuMobileAberto && (
        <div 
          className="fixed inset-0 bg-black/40 backdrop-blur-sm z-40 md:hidden transition-opacity"
          onClick={() => setMenuMobileAberto(false)}
        />
      )}

      {/* 🧭 SIDEBAR PREMIUM */}
      <aside className={`fixed inset-y-0 left-0 z-50 w-64 bg-[#3B4D43] text-white flex flex-col justify-between p-6 transform transition-transform duration-300 ease-in-out md:relative md:translate-x-0 shadow-2xl md:shadow-none ${menuMobileAberto ? 'translate-x-0' : '-translate-x-full'}`}>
        <div>
          <div className="flex items-center justify-between md:justify-start gap-3 mb-10">
            <div className="flex items-center gap-3 text-emerald-400">
              <IconLeaf />
              <h1 className="text-xl font-bold tracking-wide text-white">Nutri Pro</h1>
            </div>
            <button className="md:hidden text-white/70 hover:text-white" onClick={() => setMenuMobileAberto(false)}>
              <IconX />
            </button>
          </div>
          
          <nav className="space-y-3">
            {[
              { id: 'dashboard', label: 'Visão Geral', icon: <IconLayout /> },
              { id: 'pacientes', label: 'Pacientes', icon: <IconUsers /> },
              { id: 'feed', label: 'Gestão do Feed', icon: <IconMegaphone /> },
              { id: 'chat', label: 'Consultório', icon: <IconMessage /> },
            ].map(item => (
              <button 
                key={item.id}
                onClick={() => trocarAba(item.id)} 
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-medium transition-all duration-200 text-left ${abaAtiva === item.id ? 'bg-white text-[#3B4D43] shadow-sm' : 'text-white/70 hover:bg-white/10 hover:text-white'}`}
              >
                {item.icon}
                <span className="text-sm">{item.label}</span>
              </button>
            ))}
          </nav>
        </div>
        <div className="border-t border-white/10 pt-6 text-xs text-white/40 flex justify-between items-center">
          <span>v3.0.1</span>
          <span>Painel Admin</span>
        </div>
      </aside>

      {/* 🖥️ CONTAINER CENTRAL (Header Mobile + Main Content) */}
      <div className="flex-1 flex flex-col h-screen overflow-hidden w-full relative">
        
        {/* 📱 HEADER MOBILE (Fixa no topo) */}
        <div className="md:hidden flex items-center justify-between bg-white border-b border-gray-200 px-6 py-4 z-30">
          <div className="flex items-center gap-2 text-[#3B4D43]">
            <IconLeaf />
            <span className="font-bold">Nutri Pro</span>
          </div>
          <button onClick={() => setMenuMobileAberto(true)} className="text-gray-600 focus:outline-none p-1">
            <IconMenu />
          </button>
        </div>

        {/* 📜 ÁREA DE ROLAGEM DO CONTEÚDO */}
        <main className="flex-1 overflow-y-auto p-4 md:p-8 lg:p-10 w-full">
          
          {/* =========================================
              ABA 0: DASHBOARD
          ========================================= */}
          {abaAtiva === 'dashboard' && (
            <div className="animate-fade-in max-w-6xl mx-auto">
              <header className="mb-8">
                <h2 className="text-2xl md:text-3xl font-bold text-gray-900">Visão Geral</h2>
                <p className="text-gray-500 text-sm mt-1">Bem-vindo ao seu centro de controle clínico.</p>
              </header>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-start flex-col gap-4">
                  <div className="bg-emerald-50 text-emerald-600 p-3 rounded-xl"><IconUsers /></div>
                  <div><p className="text-gray-400 text-[11px] font-bold uppercase tracking-wider mb-1">Pacientes Ativos</p><p className="text-3xl font-bold text-gray-900">{pacientes.length}</p></div>
                </div>
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-start flex-col gap-4">
                  <div className="bg-blue-50 text-blue-600 p-3 rounded-xl"><IconMegaphone /></div>
                  <div><p className="text-gray-400 text-[11px] font-bold uppercase tracking-wider mb-1">Publicações no Feed</p><p className="text-3xl font-bold text-gray-900">{postsFeed.length}</p></div>
                </div>
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-start flex-col gap-4">
                  <div className="bg-orange-50 text-orange-600 p-3 rounded-xl"><IconLayout /></div>
                  <div><p className="text-gray-400 text-[11px] font-bold uppercase tracking-wider mb-1">Status do Sistema</p><p className="text-lg font-bold text-emerald-600 mt-1 flex items-center gap-2"><span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span> Online</p></div>
                </div>
              </div>
            </div>
          )}

          {/* =========================================
              ABA 1: PACIENTES - CARDS DE PACIENTES
          ========================================= */}
          {abaAtiva === 'pacientes' && !pacienteSelecionado && (
            <div className="animate-fade-in max-w-6xl mx-auto">
              <header className="mb-8 flex flex-col md:flex-row justify-between md:items-end gap-4">
                <div>
                  <h2 className="text-2xl md:text-3xl font-bold text-gray-900">Pacientes</h2>
                  <p className="text-gray-500 text-sm mt-1">Gerencie a evolução clínica de forma individual.</p>
                </div>
              </header>
              
              {carregando ? (
                <div className="text-center py-12 text-gray-400 text-sm">Carregando base de pacientes...</div>
              ) : pacientes.length === 0 ? (
                <div className="text-center py-12 text-gray-400 text-sm bg-white rounded-2xl border border-gray-100 border-dashed">Nenhum paciente cadastrado.</div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {pacientes.map((p) => (
                    <div key={p.id} onClick={() => {setPacienteSelecionado(p); setSubAbaPaciente('resumo');}} className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-all duration-200 cursor-pointer group flex flex-col justify-between h-44">
                      <div>
                        <div className="flex justify-between items-start mb-1">
                          <h3 className="font-bold text-gray-900 truncate pr-2">{p.nome || "Sem Nome"}</h3>
                          <span className="bg-gray-50 text-gray-500 text-[10px] font-bold px-2 py-1 rounded-lg uppercase whitespace-nowrap">{p.objetivo || 'Não def.'}</span>
                        </div>
                        <p className="text-xs text-gray-400 truncate">{p.email}</p>
                      </div>
                      <div className="flex items-center justify-between pt-4 border-t border-gray-50 mt-auto">
                        <span className="text-[10px] text-gray-400 font-mono">ID: {p.id.substring(0,6)}...</span>
                        <span className="text-[#3B4D43] text-xs font-bold flex items-center gap-1 group-hover:translate-x-1 transition-transform">Prontuário <IconArrowRight /></span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* =========================================
              ABA 1: PACIENTES - PRONTUÁRIO
          ========================================= */}
          {abaAtiva === 'pacientes' && pacienteSelecionado && (
            <div className="animate-fade-in max-w-6xl mx-auto">
              <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4">
                <div>
                  <button onClick={() => setPacienteSelecionado(null)} className="text-xs font-bold text-gray-400 hover:text-[#3B4D43] mb-2 flex items-center gap-1 transition">
                    ← Voltar aos pacientes
                  </button>
                  <h2 className="text-2xl md:text-3xl font-bold text-gray-900">{pacienteSelecionado.nome}</h2>
                </div>
                <button onClick={() => excluirPaciente(pacienteSelecionado.id)} className="bg-red-50 text-red-600 hover:bg-red-600 hover:text-white border border-red-100 font-bold text-xs px-4 py-2.5 rounded-xl transition flex items-center gap-2">
                  <IconTrash /> Excluir Paciente
                </button>
              </div>

              {/* NAVEGAÇÃO INTERNA SCROLLÁVEL NO MOBILE */}
              <div className="flex overflow-x-auto gap-3 mb-8 pb-2 hide-scrollbar">
                {[
                  { id: 'resumo', label: 'Resumo Clínico' },
                  { id: 'diario', label: 'Diário & Evolução' },
                  { id: 'metas', label: 'Cardápio & Metas' },
                  { id: 'notas', label: 'Notas Privadas' }
                ].map(aba => (
                  <button key={aba.id} onClick={() => setSubAbaPaciente(aba.id)} className={`whitespace-nowrap px-4 py-2.5 rounded-xl text-xs font-bold transition-colors ${subAbaPaciente === aba.id ? 'bg-[#3B4D43] text-white shadow-sm' : 'bg-white text-gray-500 border border-gray-200 hover:bg-gray-50'}`}>
                    {aba.label}
                  </button>
                ))}
              </div>

              {/* CONTEÚDO: RESUMO */}
              {subAbaPaciente === 'resumo' && (
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
                    <h3 className="font-bold text-gray-900 mb-5 text-sm uppercase tracking-wider">Ficha Cadastral</h3>
                    <div className="grid grid-cols-2 gap-4 text-sm mb-4">
                      <div className="bg-gray-50 p-4 rounded-xl"><span className="text-[10px] text-gray-400 font-bold block mb-1">IDADE / GÊNERO</span><span className="font-bold text-gray-800">{pacienteSelecionado.idade || '-'}a • {pacienteSelecionado.genero || '-'}</span></div>
                      <div className="bg-gray-50 p-4 rounded-xl"><span className="text-[10px] text-gray-400 font-bold block mb-1">ALTURA / PESO INICIAL</span><span className="font-bold text-gray-800">{pacienteSelecionado.altura || '-'}m • {pacienteSelecionado.peso_inicial || '-'}kg</span></div>
                    </div>
                    <div className="border border-gray-100 p-4 rounded-xl mb-4"><span className="text-[10px] text-gray-400 font-bold block mb-1">OBJETIVO & NÍVEL DE ATIVIDADE</span><span className="font-bold text-gray-800">{pacienteSelecionado.objetivo || '-'} • {pacienteSelecionado.nivel_atividade || '-'}</span></div>
                    <div className="bg-red-50 p-4 rounded-xl border border-red-100"><span className="text-[10px] text-red-500 font-bold block mb-1">RESTRIÇÕES ALIMENTARES</span><span className="font-bold text-red-800">{pacienteSelecionado.restricao_alimentar || 'Nenhuma declarada'}</span></div>
                  </div>
                  
                  <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col">
                    <h3 className="font-bold text-gray-900 mb-5 text-sm uppercase tracking-wider">Evolução de Peso</h3>
                    <div className="relative w-full flex-1 min-h-[180px] bg-gray-50 rounded-xl p-4 border border-gray-100 flex flex-col justify-end">
                      {historicoPesoReal.length < 2 ? <p className="text-xs text-gray-400 m-auto text-center px-8">Aguardando novos registros de peso no aplicativo do paciente para gerar a curva evolutiva.</p> : (
                        <>
                          <svg className="absolute inset-0 w-full h-full p-4" viewBox="0 0 1000 100" preserveAspectRatio="none"><path d={construirCaminhoSVG()} fill="none" stroke="#3B4D43" strokeWidth="4" strokeLinecap="round"/></svg>
                          <div className="flex justify-between text-[10px] text-gray-400 font-bold z-10 w-full mt-auto">
                            {historicoPesoReal.map((h, i) => <div key={i} className="text-center bg-white/80 px-2 py-1 rounded-md backdrop-blur-sm shadow-sm"><p className="text-gray-800">{h.peso}kg</p><p className="font-medium text-gray-400 mt-0.5">{h.data ? h.data.split('-').slice(1).reverse().join('/') : ''}</p></div>)}
                          </div>
                        </>
                      )}
                    </div>
                  </div>
                </div>
              )}

              {/* CONTEÚDO: DIÁRIO */}
              {subAbaPaciente === 'diario' && (
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
                    <h3 className="font-bold text-gray-900 mb-5 text-sm uppercase tracking-wider">Diário do Paciente (Hoje)</h3>
                    <div className="flex gap-4 mb-6">
                      <div className="flex-1 bg-emerald-50 border border-emerald-100 p-4 rounded-xl text-center"><p className="text-[10px] font-bold text-emerald-600 uppercase mb-1">Calorias Ingeridas</p><p className="text-2xl font-bold text-emerald-900">{dadosDiario?.calorias_consumidas || 0}</p></div>
                      <div className="flex-1 bg-blue-50 border border-blue-100 p-4 rounded-xl text-center"><p className="text-[10px] font-bold text-blue-600 uppercase mb-1">Água (ml)</p><p className="text-2xl font-bold text-blue-900">{dadosDiario?.agua_consumida || 0}</p></div>
                    </div>
                    <ul className="space-y-2 max-h-[300px] overflow-y-auto pr-2">
                      {(!dadosDiario?.historico_alimentos || dadosDiario.historico_alimentos.length === 0) ? <p className="text-sm text-gray-400 bg-gray-50 p-4 rounded-xl border border-dashed border-gray-200 text-center">Paciente não registrou alimentos hoje.</p> : 
                        dadosDiario.historico_alimentos.map((item, idx) => (
                          <li key={idx} className="flex justify-between items-center p-3 bg-white border border-gray-100 shadow-sm rounded-xl text-sm">
                            <div><p className="font-bold text-gray-800 text-xs mb-0.5">{item.nome}</p><p className="text-[10px] text-gray-400 uppercase font-medium">{item.turno} • {item.quantidade}x {item.medida_escolhida}</p></div>
                            <span className="font-bold text-emerald-600 text-xs bg-emerald-50 px-2 py-1 rounded-md">{item.calorias} kcal</span>
                          </li>
                        ))
                      }
                    </ul>
                  </div>
                  <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
                    <h3 className="font-bold text-gray-900 mb-5 text-sm uppercase tracking-wider">Galeria de Evolução</h3>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <p className="text-[10px] font-bold text-gray-400 uppercase text-center">Foto Inicial</p>
                        <div className="aspect-[3/4] bg-gray-50 border border-gray-100 rounded-xl bg-cover bg-center overflow-hidden" style={{backgroundImage: `url(${fotosPaciente.antes_1 || ''})`}}>{!fotosPaciente.antes_1 && <span className="flex items-center justify-center h-full text-gray-300 text-xs px-4 text-center">Sem imagem</span>}</div>
                      </div>
                      <div className="space-y-2">
                        <p className="text-[10px] font-bold text-gray-400 uppercase text-center">Foto Atual</p>
                        <div className="aspect-[3/4] bg-gray-50 border border-gray-100 rounded-xl bg-cover bg-center overflow-hidden" style={{backgroundImage: `url(${fotosPaciente.depois_1 || ''})`}}>{!fotosPaciente.depois_1 && <span className="flex items-center justify-center h-full text-gray-300 text-xs px-4 text-center">Sem imagem</span>}</div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* CONTEÚDO: METAS */}
              {subAbaPaciente === 'metas' && (
                <form onSubmit={salvarPlanoEMetas} className="bg-white p-6 md:p-8 rounded-2xl border border-gray-100 shadow-sm">
                  <h3 className="font-bold text-gray-900 mb-6 text-sm uppercase tracking-wider">Prescrição Clínica e Metas</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                    <div><label className="block text-xs font-bold text-gray-400 uppercase mb-2">Meta Calórica Diária (kcal)</label><input type="number" value={novaMetaCalorias} onChange={(e)=>setNovaMetaCalorias(e.target.value)} className="w-full bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] transition" /></div>
                    <div><label className="block text-xs font-bold text-gray-400 uppercase mb-2">Meta Hídrica Diária (ml)</label><input type="number" value={novaMetaAgua} onChange={(e)=>setNovaMetaAgua(e.target.value)} className="w-full bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] transition" /></div>
                  </div>
                  <h4 className="text-xs font-bold text-gray-400 uppercase mb-4 border-b border-gray-100 pb-2">Plano Alimentar Sincronizado</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                    <div><label className="block text-[11px] font-bold text-gray-500 mb-2">CAFÉ DA MANHÃ</label><textarea value={planoCafe} onChange={(e)=>setPlanoCafe(e.target.value)} className="w-full h-24 bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm resize-none focus:outline-[#3B4D43]" /></div>
                    <div><label className="block text-[11px] font-bold text-gray-500 mb-2">ALMOÇO</label><textarea value={planoAlmoco} onChange={(e)=>setPlanoAlmoco(e.target.value)} className="w-full h-24 bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm resize-none focus:outline-[#3B4D43]" /></div>
                    <div><label className="block text-[11px] font-bold text-gray-500 mb-2">LANCHE</label><textarea value={planoLanche} onChange={(e)=>setPlanoLanche(e.target.value)} className="w-full h-24 bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm resize-none focus:outline-[#3B4D43]" /></div>
                    <div><label className="block text-[11px] font-bold text-gray-500 mb-2">JANTAR</label><textarea value={planoJantar} onChange={(e)=>setPlanoJantar(e.target.value)} className="w-full h-24 bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm resize-none focus:outline-[#3B4D43]" /></div>
                  </div>
                  <div className="flex justify-end pt-4 border-t border-gray-100">
                    <button type="submit" className="w-full md:w-auto bg-[#3B4D43] text-white text-sm font-bold px-8 py-3 rounded-xl hover:bg-[#2C3E35] transition shadow-sm">Salvar Prescrição no App</button>
                  </div>
                </form>
              )}

              {/* CONTEÚDO: NOTAS */}
              {subAbaPaciente === 'notas' && (
                <div className="bg-amber-50 p-6 md:p-8 rounded-2xl border border-amber-100 shadow-sm max-w-3xl">
                  <h3 className="font-bold text-amber-900 mb-2 text-sm uppercase tracking-wider">Anotações Internas Privadas</h3>
                  <p className="text-xs text-amber-700/70 mb-6">Este espaço é visível estritamente para o administrador clínico.</p>
                  <textarea value={notasInternas} onChange={(e) => setNotasInternas(e.target.value)} placeholder="Anotações sobre queixas, evolução, suplementação recomendada internamente..." className="w-full h-64 bg-white border border-amber-200/60 rounded-xl p-5 text-sm focus:outline-amber-500 resize-none mb-6 shadow-sm text-gray-700 leading-relaxed" />
                  <div className="flex justify-end">
                    <button onClick={salvarNotas} disabled={salvandoNotas} className="w-full md:w-auto bg-amber-600 text-white text-sm font-bold px-8 py-3 rounded-xl hover:bg-amber-700 transition shadow-sm">{salvandoNotas ? 'Salvando...' : 'Salvar Anotações'}</button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* =========================================
              ABA 2: FEED
          ========================================= */}
          {abaAtiva === 'feed' && (
            <div className="animate-fade-in max-w-4xl mx-auto">
              <header className="mb-8">
                <h2 className="text-2xl md:text-3xl font-bold text-gray-900">Mural Educacional</h2>
                <p className="text-gray-500 text-sm mt-1">Publique comunicações para toda a base de pacientes simultaneamente.</p>
              </header>
              <form onSubmit={publicarNoFeed} className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm mb-8">
                <textarea value={novoPostTexto} onChange={(e) => setNovoPostTexto(e.target.value)} placeholder="O que você gostaria de compartilhar com seus pacientes hoje?" className="w-full h-32 bg-gray-50 border border-gray-200 rounded-xl p-4 text-sm focus:outline-[#3B4D43] resize-none mb-4 transition" />
                <div className="flex justify-end">
                  <button type="submit" className="w-full md:w-auto bg-[#3B4D43] text-white text-sm font-bold px-8 py-3 rounded-xl hover:bg-[#2C3E35] transition flex items-center justify-center gap-2 shadow-sm">
                    <IconMegaphone /> Publicar no Feed
                  </button>
                </div>
              </form>
              <h3 className="font-bold text-gray-900 mb-4 text-sm uppercase tracking-wider">Histórico de Publicações</h3>
              <div className="space-y-4">
                {postsFeed.length === 0 ? <div className="text-center py-12 text-gray-400 text-sm bg-white rounded-2xl border border-gray-100 border-dashed">Nenhuma postagem ativa.</div> : 
                 postsFeed.map(post => (
                  <div key={post.id} className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm relative group flex flex-col sm:flex-row gap-4 justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <div className="bg-emerald-100 p-1.5 rounded-full text-emerald-600"><IconLayout /></div>
                        <span className="text-[10px] text-gray-500 font-bold uppercase">{post.autor}</span>
                      </div>
                      <p className="text-sm text-gray-700 leading-relaxed pr-4">{post.texto}</p>
                      <div className="mt-4 flex items-center gap-1 text-[11px] text-gray-400 font-bold bg-gray-50 w-fit px-2 py-1 rounded-md border border-gray-100">
                        <span className="text-red-500">♥</span> {post.curtidas?.length || 0}
                      </div>
                    </div>
                    <button onClick={() => excluirPost(post.id)} className="sm:opacity-0 group-hover:opacity-100 text-red-500 bg-red-50 p-2 rounded-lg transition-all hover:bg-red-500 hover:text-white shrink-0">
                      <IconTrash />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* =========================================
              ABA 3: CHAT
          ========================================= */}
          {abaAtiva === 'chat' && (
            <div className="h-[calc(100vh-10rem)] md:h-[calc(100vh-8rem)] flex flex-col md:flex-row gap-4 md:gap-6 animate-fade-in max-w-6xl mx-auto">
              
              <div className={`w-full md:w-80 bg-white border border-gray-100 rounded-2xl overflow-hidden shadow-sm flex flex-col shrink-0 ${pacienteChatSelecionado ? 'hidden md:flex' : 'flex'}`}>
                <div className="p-4 border-b border-gray-100 bg-gray-50">
                  <h3 className="font-bold text-sm text-gray-900 uppercase tracking-wider">Canais Privados</h3>
                </div>
                <div className="flex-1 overflow-y-auto p-3 space-y-2">
                  {pacientes.map(p => (
                    <button key={p.id} onClick={() => setPacienteChatSelecionado(p)} className={`w-full text-left p-3 rounded-xl transition-all duration-200 flex flex-col border ${pacienteChatSelecionado?.id === p.id ? 'bg-[#3B4D43] border-[#3B4D43] text-white shadow-md' : 'bg-white border-transparent hover:bg-gray-50 text-gray-700'}`}>
                      <span className="font-bold text-sm truncate">{p.nome || "Sem Nome"}</span>
                      <span className={`text-[10px] mt-1 font-medium ${pacienteChatSelecionado?.id === p.id ? 'text-emerald-200' : 'text-gray-400'}`}>Toque para abrir</span>
                    </button>
                  ))}
                </div>
              </div>
              
              <div className={`flex-1 bg-white border border-gray-100 rounded-2xl flex flex-col justify-between overflow-hidden shadow-sm ${pacienteChatSelecionado ? 'flex' : 'hidden md:flex'}`}>
                {pacienteChatSelecionado ? (
                  <>
                    <header className="p-4 border-b border-gray-100 bg-white flex items-center gap-3 shadow-sm z-10">
                      <button onClick={() => setPacienteChatSelecionado(null)} className="md:hidden text-gray-400 hover:text-gray-600 bg-gray-50 p-2 rounded-lg">
                        <IconX />
                      </button>
                      <div>
                        <h4 className="font-bold text-gray-900 text-sm">{pacienteChatSelecionado.nome}</h4>
                        <span className="text-[10px] text-emerald-500 font-bold uppercase tracking-wider flex items-center gap-1"><span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span> Conectado</span>
                      </div>
                    </header>
                    
                    <div className="flex-1 p-4 md:p-6 overflow-y-auto bg-gray-50 space-y-4">
                      {mensagensChat.length === 0 ? <p className="text-center text-gray-400 text-xs italic pt-8">Este chat ainda não possui mensagens.</p> : 
                        mensagensChat.map(m => {
                          const souEu = m.remetente === 'nutri';
                          return (
                            <div key={m.id} className={`flex ${souEu ? 'justify-end' : 'justify-start'}`}>
                              <div className={`max-w-[85%] md:max-w-[70%] p-3.5 rounded-2xl text-sm shadow-sm ${souEu ? 'bg-[#3B4D43] text-white rounded-br-sm' : 'bg-white text-gray-700 border border-gray-100 rounded-bl-sm'}`}>
                                {m.texto}
                              </div>
                            </div>
                          );
                        })
                      }
                    </div>
                    
                    <form onSubmit={enviarMensagemChat} className="p-4 border-t border-gray-100 bg-white flex gap-3">
                      <input type="text" value={novaMensagemTexto} onChange={(e) => setNovaMensagemTexto(e.target.value)} placeholder="Mensagem para o paciente..." className="flex-1 bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-[#3B4D43] transition" />
                      <button type="submit" disabled={!novaMensagemTexto.trim()} className="bg-[#3B4D43] text-white px-5 py-3 rounded-xl hover:bg-[#2C3E35] transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m22 2-7 20-4-9-9-4Z"/><path d="M22 2 11 13"/></svg>
                      </button>
                    </form>
                  </>
                ) : (
                  <div className="flex-1 flex flex-col items-center justify-center p-8 text-gray-400 bg-gray-50">
                    <div className="bg-white p-4 rounded-full shadow-sm mb-4 text-gray-300"><IconMessage /></div>
                    <p className="text-sm font-medium">Selecione um paciente no menu lateral para iniciar o atendimento.</p>
                  </div>
                )}
              </div>
            </div>
          )}

        </main>
      </div>
    </div>
  );
}
