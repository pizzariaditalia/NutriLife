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
const IconFileText = () => <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>;
const IconAlert = () => <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/></svg>;
const IconTrophy = () => <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/></svg>;
const IconMenu = () => <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="18" y2="18"/></svg>;
const IconX = () => <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>;
const IconTrash = () => <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>;
const IconLeaf = () => <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 12 12"/></svg>;
const IconCalendar = () => <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>;
const IconPrinter = () => <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>;
const IconSearch = () => <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>;
const IconLoader = () => <svg className="animate-spin" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>;

// ==========================================
// 🍎 BANCO DE DADOS LOCAL (Alimentos Limpos / Base TACO)
// ==========================================
const BANCO_LOCAL = [
  { id: 'loc_1', nome: "Arroz Branco (cozido)", kcal100g: 130 },
  { id: 'loc_2', nome: "Arroz Integral (cozido)", kcal100g: 112 },
  { id: 'loc_3', nome: "Feijão Carioca (cozido)", kcal100g: 76 },
  { id: 'loc_4', nome: "Feijão Preto (cozido)", kcal100g: 73 },
  { id: 'loc_5', nome: "Batata Doce (cozida)", kcal100g: 86 },
  { id: 'loc_6', nome: "Mandioca / Aipim (cozido)", kcal100g: 125 },
  { id: 'loc_7', nome: "Macarrão de Trigo (cozido)", kcal100g: 131 },
  { id: 'loc_8', nome: "Aveia em Flocos", kcal100g: 394 },
  { id: 'loc_9', nome: "Tapioca (goma hidratada)", kcal100g: 240 },
  { id: 'loc_10', nome: "Pão Francês", kcal100g: 300 },
  { id: 'loc_11', nome: "Peito de Frango (grelhado)", kcal100g: 165 },
  { id: 'loc_12', nome: "Patinho Moído (refogado)", kcal100g: 133 },
  { id: 'loc_13', nome: "Filé de Tilápia / Salmão", kcal100g: 200 },
  { id: 'loc_14', nome: "Ovo de Galinha Cozido", kcal100g: 155 },
  { id: 'loc_15', nome: "Ovo Mexido (com fio de óleo)", kcal100g: 190 },
  { id: 'loc_16', nome: "Leite Integral (líquido)", kcal100g: 62 },
  { id: 'loc_17', nome: "Leite Desnatado (líquido)", kcal100g: 35 },
  { id: 'loc_18', nome: "Queijo Mussarela", kcal100g: 300 },
  { id: 'loc_19', nome: "Banana Prata", kcal100g: 98 },
  { id: 'loc_20', nome: "Maçã", kcal100g: 52 },
  { id: 'loc_21', nome: "Abacate", kcal100g: 160 },
  { id: 'loc_22', nome: "Alface", kcal100g: 15 },
  { id: 'loc_23', nome: "Tomate", kcal100g: 18 },
  { id: 'loc_24', nome: "Azeite de Oliva Extra Virgem", kcal100g: 884 }
];

export default function App() {
  const [abaAtiva, setAbaAtiva] = useState('dashboard'); 
  const [subAbaPaciente, setSubAbaPaciente] = useState('resumo'); 
  const [menuMobileAberto, setMenuMobileAberto] = useState(false);
  
  const [pacientes, setPacientes] = useState([]);
  const [postsFeed, setPostsFeed] = useState([]);
  const [modelosDieta, setModelosDieta] = useState([]);
  const [carregando, setCarregando] = useState(true);
  
  const [pacienteSelecionado, setPacienteSelecionado] = useState(null);
  const [dadosDiario, setDadosDiario] = useState(null);
  const [historicoPesoReal, setHistoricoPesoReal] = useState([]);
  const [fotosPaciente, setFotosPaciente] = useState({});
  const [notasInternas, setNotasInternas] = useState("");
  
  const [novaMetaCalorias, setNovaMetaCalorias] = useState(2000);
  const [novaMetaAgua, setNovaMetaAgua] = useState(2500);
  const [planoCafe, setPlanoCafe] = useState("");
  const [planoAlmoco, setPlanoAlmoco] = useState("");
  const [planoLanche, setPlanoLanche] = useState("");
  const [planoJantar, setPlanoJantar] = useState("");
  const [dataConsulta, setDataConsulta] = useState("");
  const [linkConsulta, setLinkConsulta] = useState("");

  const [novoModeloNome, setNovoModeloNome] = useState("");
  const [novoPostTexto, setNovoPostTexto] = useState("");
  const [pacienteChatSelecionado, setPacienteChatSelecionado] = useState(null);
  const [mensagensChat, setMensagensChat] = useState([]);
  const [novaMensagemTexto, setNovaMensagemTexto] = useState("");

  // 🍎 ESTADOS DA CALCULADORA HÍBRIDA (LOCAL + API)
  const [buscaAlimento, setBuscaAlimento] = useState("");
  const [resultadosBusca, setResultadosBusca] = useState([]);
  const [buscandoAPI, setBuscandoAPI] = useState(false);
  const [alimentoSelecionadoCalc, setAlimentoSelecionadoCalc] = useState(null);
  const [quantidadeCalc, setQuantidadeCalc] = useState(100);

  const dataHoje = new Date().toISOString().split('T')[0];

  useEffect(() => {
    const unsubPacientes = onSnapshot(collection(db, 'usuarios'), (snapshot) => {
      setPacientes(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setCarregando(false);
    });
    const unsubFeed = onSnapshot(query(collection(db, 'feed'), orderBy('timestamp', 'desc')), (snapshot) => {
      setPostsFeed(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });
    const unsubModelos = onSnapshot(collection(db, 'modelos_dieta'), (snapshot) => {
      setModelosDieta(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });
    return () => { unsubPacientes(); unsubFeed(); unsubModelos(); };
  }, []);

  useEffect(() => {
    if (!pacienteSelecionado) return;
    if (pacienteSelecionado.plano_alimentar) {
      setPlanoCafe(pacienteSelecionado.plano_alimentar.cafe || "");
      setPlanoAlmoco(pacienteSelecionado.plano_alimentar.almoco || "");
      setPlanoLanche(pacienteSelecionado.plano_alimentar.lanche || "");
      setPlanoJantar(pacienteSelecionado.plano_alimentar.jantar || "");
    } else {
      setPlanoCafe(""); setPlanoAlmoco(""); setPlanoLanche(""); setPlanoJantar("");
    }
    setNotasInternas(pacienteSelecionado.notas_nutri || "");
    setDataConsulta(pacienteSelecionado.agenda?.data || "");
    setLinkConsulta(pacienteSelecionado.agenda?.link || "");

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

  // 🚀 O MOTOR DE BUSCA MUNDIAL (API OpenFoodFacts + Banco Local)
  useEffect(() => {
    if (buscaAlimento.trim().length < 2) {
      setResultadosBusca([]);
      setBuscandoAPI(false);
      return;
    }

    // 1. Busca Local Rápida (Sempre mostra primeiro)
    const termo = buscaAlimento.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
    const local = BANCO_LOCAL.filter(a => a.nome.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").includes(termo));
    setResultadosBusca(local);

    // 2. Busca na API Mundial (Debounce para não travar o servidor)
    setBuscandoAPI(true);
    const timeoutId = setTimeout(async () => {
      try {
        const res = await fetch(`https://br.openfoodfacts.org/cgi/search.pl?search_terms=${encodeURIComponent(buscaAlimento)}&search_simple=1&action=process&json=1&page_size=10`);
        const data = await res.json();
        if (data.products) {
          const apiMapeada = data.products
            .filter(p => p.product_name && p.nutriments && p.nutriments['energy-kcal_100g'])
            .map(p => ({
              id: p.code,
              nome: `${p.product_name} ${p.brands ? `(${p.brands.split(',')[0]})` : ''}`,
              kcal100g: Math.round(p.nutriments['energy-kcal_100g'])
            }));
          
          // Junta a lista local com a lista mundial sem repetir nomes idênticos
          setResultadosBusca(prev => {
            const combinada = [...prev, ...apiMapeada];
            const unicos = combinada.filter((v, i, a) => a.findIndex(t => (t.nome === v.nome)) === i);
            return unicos;
          });
        }
      } catch (e) { console.error("Erro na API Mundial:", e); }
      finally { setBuscandoAPI(false); }
    }, 800); // 800ms de delay para não sobrecarregar

    return () => clearTimeout(timeoutId);
  }, [buscaAlimento]);

  const trocarAba = (aba) => { setAbaAtiva(aba); setMenuMobileAberto(false); if(aba !== 'pacientes') setPacienteSelecionado(null); };

  const excluirPaciente = async (id) => {
    if(window.confirm("ALERTA: Tem certeza que deseja excluir este paciente?")) {
      try { await deleteDoc(doc(db, 'usuarios', id)); setPacienteSelecionado(null); } catch(e) { alert("Erro ao excluir."); }
    }
  };

  const salvarPlanoEMetas = async (e) => {
    e.preventDefault();
    if (!pacienteSelecionado) return;
    try {
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id), { plano_alimentar: { cafe: planoCafe, almoco: planoAlmoco, lanche: planoLanche, jantar: planoJantar } });
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id, 'diario', dataHoje), { meta_calorias: Number(novaMetaCalorias), meta_agua: Number(novaMetaAgua) });
      alert("✅ Cardápio e metas sincronizados com sucesso!");
    } catch (e) { alert("Erro ao salvar."); }
  };

  const salvarNotasEAgenda = async () => {
    try {
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id), { notas_nutri: notasInternas, agenda: { data: dataConsulta, link: linkConsulta } });
      alert("✅ Dados salvos!");
    } catch(e) { alert("Erro ao salvar."); }
  };

  const salvarNovoModelo = async (e) => {
    e.preventDefault();
    if (novoModeloNome.trim() === "") return;
    try {
      await addDoc(collection(db, 'modelos_dieta'), { nome: novoModeloNome, cafe: planoCafe, almoco: planoAlmoco, lanche: planoLanche, jantar: planoJantar, timestamp: serverTimestamp() });
      setNovoModeloNome(""); alert("✅ Template salvo!");
    } catch (e) { alert("Erro ao salvar."); }
  };

  const aplicarModelo = (modeloId) => {
    if(modeloId === "") return;
    const modelo = modelosDieta.find(m => m.id === modeloId);
    if(modelo) { setPlanoCafe(modelo.cafe || ""); setPlanoAlmoco(modelo.almoco || ""); setPlanoLanche(modelo.lanche || ""); setPlanoJantar(modelo.jantar || ""); }
  };

  const publicarNoFeed = async (e) => {
    e.preventDefault();
    if (novoPostTexto.trim() === "") return;
    await addDoc(collection(db, 'feed'), { autor: "Nutricionista Oficial", texto: novoPostTexto.trim(), curtidas: [], timestamp: serverTimestamp() });
    setNovoPostTexto("");
  };

  const enviarMensagemChat = async (e) => {
    e.preventDefault();
    if (novaMensagemTexto.trim() === "" || !pacienteChatSelecionado) return;
    await addDoc(collection(db, 'chats', pacienteChatSelecionado.id, 'mensagens'), { texto: novaMensagemTexto.trim(), remetente: 'nutri', timestamp: serverTimestamp() });
    setNovaMensagemTexto("");
  };

  const calcularKcalAtual = () => {
    if(!alimentoSelecionadoCalc) return 0;
    return Math.round((alimentoSelecionadoCalc.kcal100g / 100) * quantidadeCalc);
  };

  const injetarAlimentoNoTurno = (turno, setTurnoState, valorAtual) => {
    if(!alimentoSelecionadoCalc) return;
    const calorias = calcularKcalAtual();
    const novaLinha = `• ${quantidadeCalc}g de ${alimentoSelecionadoCalc.nome} (${calorias} kcal)\n`;
    setTurnoState(valorAtual + (valorAtual ? "\n" : "") + novaLinha);
    setBuscaAlimento(""); setAlimentoSelecionadoCalc(null);
  };

  const imprimirProntuario = () => window.print();

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
      <style>{`
        @media print {
          aside, .no-print, header button, .md\\:hidden { display: none !important; }
          main { padding: 0 !important; overflow: visible !important; height: auto !important; }
          .bg-\\[\\#F9F6F0\\] { background: white !important; }
          .shadow-sm { box-shadow: none !important; border: 1px solid #eee !important; }
          textarea { border: none !important; resize: none !important; height: auto !important; overflow: hidden !important; }
          body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
          .print-header { display: block !important; margin-bottom: 20px; text-align: center; border-bottom: 2px solid #3B4D43; padding-bottom: 10px; }
        }
        .print-header { display: none; }
      `}</style>

      {menuMobileAberto && <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-40 md:hidden transition-opacity" onClick={() => setMenuMobileAberto(false)} />}

      <aside className={`fixed inset-y-0 left-0 z-50 w-64 bg-[#3B4D43] text-white flex flex-col justify-between p-6 transform transition-transform duration-300 ease-in-out md:relative md:translate-x-0 shadow-2xl md:shadow-none ${menuMobileAberto ? 'translate-x-0' : '-translate-x-full'}`}>
        <div>
          <div className="flex items-center justify-between md:justify-start gap-3 mb-10">
            <div className="flex items-center gap-3 text-emerald-400"><IconLeaf /><h1 className="text-xl font-bold tracking-wide text-white">Nutri Pro</h1></div>
            <button className="md:hidden text-white/70 hover:text-white" onClick={() => setMenuMobileAberto(false)}><IconX /></button>
          </div>
          <nav className="space-y-3">
            {[{ id: 'dashboard', label: 'Visão Geral', icon: <IconLayout /> }, { id: 'pacientes', label: 'Pacientes', icon: <IconUsers /> }, { id: 'templates', label: 'Banco de Dietas', icon: <IconFileText /> }, { id: 'feed', label: 'Gestão do Feed', icon: <IconMegaphone /> }, { id: 'chat', label: 'Consultório', icon: <IconMessage /> }].map(item => (
              <button key={item.id} onClick={() => trocarAba(item.id)} className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-medium transition-all duration-200 text-left ${abaAtiva === item.id ? 'bg-white text-[#3B4D43] shadow-sm' : 'text-white/70 hover:bg-white/10 hover:text-white'}`}>{item.icon}<span className="text-sm">{item.label}</span></button>
            ))}
          </nav>
        </div>
        <div className="border-t border-white/10 pt-6 text-xs text-white/40 flex justify-between items-center"><span>v6.0 API Global</span><span>Admin</span></div>
      </aside>

      <div className="flex-1 flex flex-col h-screen overflow-hidden w-full relative">
        <div className="md:hidden flex items-center justify-between bg-white border-b border-gray-200 px-6 py-4 z-30">
          <div className="flex items-center gap-2 text-[#3B4D43]"><IconLeaf /><span className="font-bold">Nutri Pro</span></div>
          <button onClick={() => setMenuMobileAberto(true)} className="text-gray-600 focus:outline-none p-1"><IconMenu /></button>
        </div>

        <main className="flex-1 overflow-y-auto p-4 md:p-8 lg:p-10 w-full relative">
          <div className="print-header"><h1 style={{ color: '#3B4D43', fontSize: '24px', fontWeight: 'bold' }}>Clínica Nutri Life Pro</h1><p style={{ color: '#666', fontSize: '12px' }}>Plano Alimentar e Acompanhamento Clínico</p></div>

          {abaAtiva === 'dashboard' && (
            <div className="animate-fade-in max-w-6xl mx-auto no-print">
              <header className="mb-8"><h2 className="text-2xl md:text-3xl font-bold text-gray-900">Inteligência Clínica</h2><p className="text-gray-500 text-sm mt-1">Sua central de monitoramento em tempo real.</p></header>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-start flex-col gap-4"><div className="bg-emerald-50 text-emerald-600 p-3 rounded-xl"><IconUsers /></div><div><p className="text-gray-400 text-[11px] font-bold uppercase tracking-wider mb-1">Pacientes Ativos</p><p className="text-3xl font-bold text-gray-900">{pacientes.length}</p></div></div>
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-start flex-col gap-4"><div className="bg-blue-50 text-blue-600 p-3 rounded-xl"><IconFileText /></div><div><p className="text-gray-400 text-[11px] font-bold uppercase tracking-wider mb-1">Dietas no Banco</p><p className="text-3xl font-bold text-gray-900">{modelosDieta.length}</p></div></div>
                <div className="bg-gradient-to-br from-[#3B4D43] to-[#2C3E35] p-6 rounded-2xl shadow-sm flex items-start flex-col gap-4 text-white"><div className="bg-white/20 p-3 rounded-xl"><IconTrophy /></div><div><p className="text-white/60 text-[11px] font-bold uppercase tracking-wider mb-1">Impacto Global Estimado</p><p className="text-2xl font-bold text-white mt-1">+ {pacientes.length * 2.5} kg eliminados</p></div></div>
              </div>
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm"><div className="flex items-center gap-2 mb-6"><div className="text-red-500"><IconAlert /></div><h3 className="font-bold text-gray-900 text-sm uppercase tracking-wider">Radar de Atenção</h3></div><ul className="space-y-3">{pacientes.slice(0, 3).map((p, i) => (<li key={i} className="flex items-center justify-between p-3 bg-red-50 border border-red-100 rounded-xl"><div><p className="text-sm font-bold text-gray-800">{p.nome || 'Paciente'}</p><p className="text-[10px] text-red-600 uppercase font-medium">Baixo engajamento</p></div><button onClick={() => {setPacienteChatSelecionado(p); trocarAba('chat');}} className="text-xs bg-white border border-red-200 text-red-600 px-3 py-1.5 rounded-lg font-bold hover:bg-red-600 hover:text-white transition">Cobrar</button></li>))}{pacientes.length === 0 && <p className="text-sm text-gray-400">Nenhum alerta pendente.</p>}</ul></div>
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm"><div className="flex items-center gap-2 mb-6"><div className="text-amber-500"><IconTrophy /></div><h3 className="font-bold text-gray-900 text-sm uppercase tracking-wider">Destaques da Semana</h3></div><ul className="space-y-3">{pacientes.slice(0, 2).map((p, i) => (<li key={i} className="flex items-center justify-between p-3 bg-amber-50 border border-amber-100 rounded-xl"><div><p className="text-sm font-bold text-gray-800">{p.nome || 'Paciente'}</p><p className="text-[10px] text-amber-700 uppercase font-medium">Bateu metas perfeitamente</p></div><span className="text-xl">🔥</span></li>))}{pacientes.length === 0 && <p className="text-sm text-gray-400">Dados insuficientes.</p>}</ul></div>
              </div>
            </div>
          )}

          {abaAtiva === 'templates' && (
            <div className="animate-fade-in max-w-6xl mx-auto no-print">
              <header className="mb-8"><h2 className="text-2xl md:text-3xl font-bold text-gray-900">Banco de Dietas</h2><p className="text-gray-500 text-sm mt-1">Crie templates prontos para acelerar sua prescrição clínica.</p></header>
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="lg:col-span-2 bg-white p-6 md:p-8 rounded-2xl border border-gray-100 shadow-sm h-fit"><h3 className="font-bold text-gray-900 mb-6 text-sm uppercase tracking-wider">Criar Novo Template</h3><form onSubmit={salvarNovoModelo}><div className="mb-6"><label className="block text-xs font-bold text-gray-500 mb-2">Nome do Modelo</label><input type="text" value={novoModeloNome} onChange={(e)=>setNovoModeloNome(e.target.value)} className="w-full bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43]" required /></div><div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6"><div><label className="block text-[10px] font-bold text-gray-400 uppercase mb-2">CAFÉ DA MANHÃ</label><textarea value={planoCafe} onChange={(e)=>setPlanoCafe(e.target.value)} className="w-full h-20 bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm resize-none focus:outline-[#3B4D43]" /></div><div><label className="block text-[10px] font-bold text-gray-400 uppercase mb-2">ALMOÇO</label><textarea value={planoAlmoco} onChange={(e)=>setPlanoAlmoco(e.target.value)} className="w-full h-20 bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm resize-none focus:outline-[#3B4D43]" /></div><div><label className="block text-[10px] font-bold text-gray-400 uppercase mb-2">LANCHE</label><textarea value={planoLanche} onChange={(e)=>setPlanoLanche(e.target.value)} className="w-full h-20 bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm resize-none focus:outline-[#3B4D43]" /></div><div><label className="block text-[10px] font-bold text-gray-400 uppercase mb-2">JANTAR</label><textarea value={planoJantar} onChange={(e)=>setPlanoJantar(e.target.value)} className="w-full h-20 bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm resize-none focus:outline-[#3B4D43]" /></div></div><div className="flex justify-end"><button type="submit" className="w-full md:w-auto bg-[#3B4D43] text-white text-sm font-bold px-8 py-3 rounded-xl hover:bg-[#2C3E35] shadow-sm">💾 Salvar no Banco</button></div></form></div>
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm h-fit"><h3 className="font-bold text-gray-900 mb-6 text-sm uppercase tracking-wider">Modelos Salvos</h3><div className="space-y-3">{modelosDieta.length === 0 ? <p className="text-sm text-gray-400 italic">Nenhum modelo salvo.</p> : modelosDieta.map(m => (<div key={m.id} className="p-4 border border-gray-100 rounded-xl bg-gray-50 group flex justify-between items-center"><p className="font-bold text-gray-800 text-sm truncate pr-2">{m.nome}</p><button onClick={() => excluirModelo(m.id)} className="text-red-400 hover:text-red-600 transition"><IconTrash /></button></div>))}</div></div>
              </div>
            </div>
          )}

          {abaAtiva === 'pacientes' && !pacienteSelecionado && (
            <div className="animate-fade-in max-w-6xl mx-auto no-print">
              <header className="mb-8 flex flex-col md:flex-row justify-between md:items-end gap-4"><div><h2 className="text-2xl md:text-3xl font-bold text-gray-900">Pacientes</h2><p className="text-gray-500 text-sm mt-1">Gerencie a evolução clínica individualmente.</p></div></header>
              {carregando ? <div className="text-center py-12 text-gray-400 text-sm">Carregando...</div> : pacientes.length === 0 ? <div className="text-center py-12 text-gray-400 text-sm bg-white rounded-2xl border border-gray-100 border-dashed">Nenhum paciente.</div> : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {pacientes.map((p) => (
                    <div key={p.id} onClick={() => {setPacienteSelecionado(p); setSubAbaPaciente('resumo');}} className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-all duration-200 cursor-pointer flex flex-col justify-between h-44">
                      <div><div className="flex justify-between items-start mb-1"><h3 className="font-bold text-gray-900 truncate pr-2">{p.nome || "Sem Nome"}</h3><span className="bg-gray-50 text-gray-500 text-[10px] font-bold px-2 py-1 rounded-lg uppercase whitespace-nowrap">{p.objetivo || 'Não def.'}</span></div><p className="text-xs text-gray-400 truncate">{p.email}</p></div>
                      <div className="flex items-center justify-between pt-4 border-t border-gray-50 mt-auto"><span className="text-[10px] text-gray-400 font-mono">ID: {p.id.substring(0,6)}...</span><span className="text-[#3B4D43] text-xs font-bold">Abrir →</span></div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {abaAtiva === 'pacientes' && pacienteSelecionado && (
            <div className="animate-fade-in max-w-6xl mx-auto">
              <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4 print-header">
                <div><button onClick={() => setPacienteSelecionado(null)} className="text-xs font-bold text-gray-400 hover:text-[#3B4D43] mb-2 transition no-print">← Voltar</button><h2 className="text-2xl md:text-3xl font-bold text-gray-900">{pacienteSelecionado.nome}</h2><p className="text-xs text-gray-500 mt-1">Prontuário Médico • ID: {pacienteSelecionado.id.substring(0,8)}</p></div>
                <div className="flex gap-2 no-print"><button onClick={imprimirProntuario} className="bg-white text-gray-700 border border-gray-200 hover:bg-gray-50 font-bold text-xs px-4 py-2.5 rounded-xl transition flex items-center gap-2"><IconPrinter /> Exportar PDF</button><button onClick={() => excluirPaciente(pacienteSelecionado.id)} className="bg-red-50 text-red-600 hover:bg-red-600 hover:text-white border border-red-100 font-bold text-xs px-4 py-2.5 rounded-xl transition flex items-center gap-2"><IconTrash /> Excluir</button></div>
              </div>

              <div className="flex overflow-x-auto gap-3 mb-8 pb-2 hide-scrollbar no-print">
                {[ { id: 'resumo', label: 'Resumo Clínico' }, { id: 'diario', label: 'Diário & Fotos' }, { id: 'metas', label: 'Cardápio & Metas' }, { id: 'notas', label: 'Notas & Agenda' }].map(aba => (
                  <button key={aba.id} onClick={() => setSubAbaPaciente(aba.id)} className={`whitespace-nowrap px-4 py-2.5 rounded-xl text-xs font-bold transition-colors ${subAbaPaciente === aba.id ? 'bg-[#3B4D43] text-white shadow-sm' : 'bg-white text-gray-500 border border-gray-200 hover:bg-gray-50'}`}>{aba.label}</button>
                ))}
              </div>

              {subAbaPaciente === 'resumo' && (
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm"><h3 className="font-bold text-gray-900 mb-5 text-sm uppercase tracking-wider">Ficha Cadastral</h3><div className="grid grid-cols-2 gap-4 text-sm mb-4"><div className="bg-gray-50 p-4 rounded-xl"><span className="text-[10px] text-gray-400 font-bold block mb-1">IDADE / GÊNERO</span><span className="font-bold text-gray-800">{pacienteSelecionado.idade || '-'}a • {pacienteSelecionado.genero || '-'}</span></div><div className="bg-gray-50 p-4 rounded-xl"><span className="text-[10px] text-gray-400 font-bold block mb-1">ALTURA / PESO INICIAL</span><span className="font-bold text-gray-800">{pacienteSelecionado.altura || '-'}m • {pacienteSelecionado.peso_inicial || '-'}kg</span></div></div><div className="border border-gray-100 p-4 rounded-xl mb-4"><span className="text-[10px] text-gray-400 font-bold block mb-1">OBJETIVO & ATIVIDADE</span><span className="font-bold text-gray-800">{pacienteSelecionado.objetivo || '-'} • {pacienteSelecionado.nivel_atividade || '-'}</span></div><div className="bg-red-50 p-4 rounded-xl border border-red-100"><span className="text-[10px] text-red-500 font-bold block mb-1">RESTRIÇÕES</span><span className="font-bold text-red-800">{pacienteSelecionado.restricao_alimentar || 'Nenhuma declarada'}</span></div></div>
                  <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col"><h3 className="font-bold text-gray-900 mb-5 text-sm uppercase tracking-wider">Evolução de Peso</h3><div className="relative w-full flex-1 min-h-[180px] bg-gray-50 rounded-xl p-4 border border-gray-100 flex flex-col justify-end">{historicoPesoReal.length < 2 ? <p className="text-xs text-gray-400 m-auto text-center px-8">Aguardando registros...</p> : (<><svg className="absolute inset-0 w-full h-full p-4" viewBox="0 0 1000 100" preserveAspectRatio="none"><path d={construirCaminhoSVG()} fill="none" stroke="#3B4D43" strokeWidth="4" strokeLinecap="round"/></svg><div className="flex justify-between text-[10px] text-gray-400 font-bold z-10 w-full mt-auto">{historicoPesoReal.map((h, i) => <div key={i} className="text-center bg-white/80 px-2 py-1 rounded-md shadow-sm"><p className="text-gray-800">{h.peso}kg</p><p className="font-medium text-gray-400 mt-0.5">{h.data ? h.data.split('-').slice(1).reverse().join('/') : ''}</p></div>)}</div></>)}</div></div>
                </div>
              )}

              {subAbaPaciente === 'diario' && (
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm"><h3 className="font-bold text-gray-900 mb-5 text-sm uppercase tracking-wider">Diário (Hoje)</h3><div className="flex gap-4 mb-6"><div className="flex-1 bg-emerald-50 border border-emerald-100 p-4 rounded-xl text-center"><p className="text-[10px] font-bold text-emerald-600 uppercase mb-1">Calorias Ingeridas</p><p className="text-2xl font-bold text-emerald-900">{dadosDiario?.calorias_consumidas || 0}</p></div><div className="flex-1 bg-blue-50 border border-blue-100 p-4 rounded-xl text-center"><p className="text-[10px] font-bold text-blue-600 uppercase mb-1">Água (ml)</p><p className="text-2xl font-bold text-blue-900">{dadosDiario?.agua_consumida || 0}</p></div></div><ul className="space-y-2 max-h-[300px] overflow-y-auto pr-2">{(!dadosDiario?.historico_alimentos || dadosDiario.historico_alimentos.length === 0) ? <p className="text-sm text-gray-400 text-center">Nenhum registro hoje.</p> : dadosDiario.historico_alimentos.map((item, idx) => (<li key={idx} className="flex justify-between items-center p-3 bg-white border border-gray-100 shadow-sm rounded-xl text-sm"><div><p className="font-bold text-gray-800 text-xs mb-0.5">{item.nome}</p><p className="text-[10px] text-gray-400 uppercase font-medium">{item.turno} • {item.quantidade}x {item.medida_escolhida}</p></div><span className="font-bold text-emerald-600 text-xs bg-emerald-50 px-2 py-1 rounded-md">{item.calorias} kcal</span></li>))}</ul></div>
                  <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm"><h3 className="font-bold text-gray-900 mb-5 text-sm uppercase tracking-wider">Galeria</h3><div className="grid grid-cols-2 gap-4"><div className="aspect-[3/4] bg-gray-50 border border-gray-100 rounded-xl bg-cover bg-center overflow-hidden" style={{backgroundImage: `url(${fotosPaciente.antes_1 || ''})`}}>{!fotosPaciente.antes_1 && <span className="flex items-center justify-center h-full text-gray-300 text-xs">Sem Imagem</span>}</div><div className="aspect-[3/4] bg-gray-50 border border-gray-100 rounded-xl bg-cover bg-center overflow-hidden" style={{backgroundImage: `url(${fotosPaciente.depois_1 || ''})`}}>{!fotosPaciente.depois_1 && <span className="flex items-center justify-center h-full text-gray-300 text-xs">Sem Imagem</span>}</div></div></div>
                </div>
              )}

              {/* 🚀 SUB-ABA METAS REFORMULADA: CALCULADORA GLOBAL DE ALIMENTOS */}
              {subAbaPaciente === 'metas' && (
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                  <form onSubmit={salvarPlanoEMetas} className="lg:col-span-2 bg-white p-6 md:p-8 rounded-2xl border border-gray-100 shadow-sm">
                    <div className="flex justify-between items-center mb-6 no-print"><h3 className="font-bold text-gray-900 text-sm uppercase tracking-wider">Prescrição Clínica</h3><select onChange={(e) => aplicarModelo(e.target.value)} className="bg-gray-50 border border-gray-200 text-xs font-bold text-gray-600 rounded-lg px-3 py-1.5 outline-none"><option value="">+ Importar Modelo Rápido...</option>{modelosDieta.map(m => <option key={m.id} value={m.id}>{m.nome}</option>)}</select></div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8"><div><label className="block text-[11px] font-bold text-gray-400 uppercase mb-2">Meta Calórica (kcal)</label><input type="number" value={novaMetaCalorias} onChange={(e)=>setNovaMetaCalorias(e.target.value)} className="w-full bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm font-bold text-[#3B4D43] focus:outline-[#3B4D43]" /></div><div><label className="block text-[11px] font-bold text-gray-400 uppercase mb-2">Meta Hídrica (ml)</label><input type="number" value={novaMetaAgua} onChange={(e)=>setNovaMetaAgua(e.target.value)} className="w-full bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm font-bold text-blue-600 focus:outline-[#3B4D43]" /></div></div>
                    <div className="space-y-4">
                      <div><label className="block text-[11px] font-bold text-gray-500 mb-1">CAFÉ DA MANHÃ</label><textarea value={planoCafe} onChange={(e)=>setPlanoCafe(e.target.value)} className="w-full h-24 bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm resize-none focus:outline-[#3B4D43]" placeholder="Insira alimentos aqui..." /></div>
                      <div><label className="block text-[11px] font-bold text-gray-500 mb-1">ALMOÇO</label><textarea value={planoAlmoco} onChange={(e)=>setPlanoAlmoco(e.target.value)} className="w-full h-24 bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm resize-none focus:outline-[#3B4D43]" placeholder="Insira alimentos aqui..." /></div>
                      <div><label className="block text-[11px] font-bold text-gray-500 mb-1">LANCHE</label><textarea value={planoLanche} onChange={(e)=>setPlanoLanche(e.target.value)} className="w-full h-24 bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm resize-none focus:outline-[#3B4D43]" placeholder="Insira alimentos aqui..." /></div>
                      <div><label className="block text-[11px] font-bold text-gray-500 mb-1">JANTAR</label><textarea value={planoJantar} onChange={(e)=>setPlanoJantar(e.target.value)} className="w-full h-24 bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm resize-none focus:outline-[#3B4D43]" placeholder="Insira alimentos aqui..." /></div>
                    </div>
                    <div className="flex justify-end pt-6 mt-4 border-t border-gray-100 no-print"><button type="submit" className="w-full md:w-auto bg-[#3B4D43] text-white text-sm font-bold px-8 py-3 rounded-xl hover:bg-[#2C3E35] transition shadow-sm">Sincronizar Prescrição no App</button></div>
                  </form>

                  <div className="lg:col-span-1 bg-white p-6 rounded-2xl border border-gray-100 shadow-sm h-fit no-print sticky top-4">
                    <h3 className="font-bold text-gray-900 mb-4 text-sm uppercase tracking-wider flex items-center gap-2"><IconSearch /> Assistente de Prescrição</h3>
                    <p className="text-xs text-gray-500 mb-4 leading-relaxed">Busque mundialmente. Se não achar, aguarde 1 seg que buscamos na nuvem.</p>
                    
                    <div className="relative">
                      <input type="text" placeholder="Buscar alimento (Ex: Aveia)..." value={buscaAlimento} onChange={(e) => setBuscaAlimento(e.target.value)} className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-emerald-500 mb-2" />
                      {buscandoAPI && <div className="absolute right-3 top-3 text-emerald-500"><IconLoader /></div>}
                    </div>

                    {/* Resultados da Busca */}
                    {buscaAlimento && !alimentoSelecionadoCalc && (
                      <div className="bg-white border border-gray-100 rounded-xl shadow-lg max-h-48 overflow-y-auto absolute w-[calc(100%-3rem)] z-10">
                        {resultadosBusca.length === 0 && !buscandoAPI ? <p className="text-xs text-gray-400 p-3">Nenhum resultado encontrado.</p> : 
                          resultadosBusca.map((a, i) => (
                            <button key={i} type="button" onClick={() => setAlimentoSelecionadoCalc(a)} className="w-full text-left p-3 hover:bg-emerald-50 border-b border-gray-50 last:border-0 transition">
                              <p className="text-xs font-bold text-gray-800 line-clamp-1">{a.nome}</p>
                              <p className="text-[10px] text-gray-400">{a.kcal100g} kcal / 100g</p>
                            </button>
                          ))
                        }
                      </div>
                    )}

                    {/* Painel da Porção (Após Selecionar) */}
                    {alimentoSelecionadoCalc && (
                      <div className="bg-emerald-50 border border-emerald-100 rounded-xl p-4 mt-4 relative">
                        <button type="button" onClick={() => {setAlimentoSelecionadoCalc(null); setBuscaAlimento("");}} className="absolute top-2 right-2 text-gray-400 hover:text-gray-700"><IconX /></button>
                        <p className="text-xs font-bold text-emerald-900 mb-3 pr-6 leading-tight">{alimentoSelecionadoCalc.nome}</p>
                        
                        <div className="flex items-center gap-3 mb-4">
                          <div className="flex-1">
                            <label className="block text-[10px] font-bold text-emerald-700 uppercase mb-1">Quantidade (g/ml)</label>
                            <input type="number" value={quantidadeCalc} onChange={(e) => setQuantidadeCalc(e.target.value)} className="w-full bg-white border border-emerald-200 rounded-lg p-2 text-sm font-bold text-gray-800 focus:outline-emerald-500" />
                          </div>
                          <div className="flex-1">
                            <label className="block text-[10px] font-bold text-emerald-700 uppercase mb-1">Calorias</label>
                            <div className="w-full bg-emerald-100 rounded-lg p-2 text-sm font-bold text-emerald-800 text-center">{calcularKcalAtual()} kcal</div>
                          </div>
                        </div>

                        <p className="text-[10px] font-bold text-gray-500 uppercase mb-2 text-center">Injetar refeição no:</p>
                        <div className="grid grid-cols-2 gap-2">
                          <button type="button" onClick={() => injetarAlimentoNoTurno('Café', setPlanoCafe, planoCafe)} className="bg-white border border-emerald-200 text-emerald-700 hover:bg-emerald-600 hover:text-white hover:border-emerald-600 text-[10px] font-bold py-2 rounded-lg transition">+ Café</button>
                          <button type="button" onClick={() => injetarAlimentoNoTurno('Almoço', setPlanoAlmoco, planoAlmoco)} className="bg-white border border-emerald-200 text-emerald-700 hover:bg-emerald-600 hover:text-white hover:border-emerald-600 text-[10px] font-bold py-2 rounded-lg transition">+ Almoço</button>
                          <button type="button" onClick={() => injetarAlimentoNoTurno('Lanche', setPlanoLanche, planoLanche)} className="bg-white border border-emerald-200 text-emerald-700 hover:bg-emerald-600 hover:text-white hover:border-emerald-600 text-[10px] font-bold py-2 rounded-lg transition">+ Lanche</button>
                          <button type="button" onClick={() => injetarAlimentoNoTurno('Jantar', setPlanoJantar, planoJantar)} className="bg-white border border-emerald-200 text-emerald-700 hover:bg-emerald-600 hover:text-white hover:border-emerald-600 text-[10px] font-bold py-2 rounded-lg transition">+ Jantar</button>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {subAbaPaciente === 'notas' && (
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 no-print">
                  <div className="bg-amber-50 p-6 md:p-8 rounded-2xl border border-amber-100 shadow-sm"><h3 className="font-bold text-amber-900 mb-2 text-sm uppercase tracking-wider">Anotações Privadas</h3><textarea value={notasInternas} onChange={(e) => setNotasInternas(e.target.value)} placeholder="Anotações internas..." className="w-full h-48 bg-white border border-amber-200/60 rounded-xl p-4 text-sm focus:outline-amber-500 resize-none mb-6 shadow-sm" /><button onClick={salvarNotasEAgenda} className="w-full md:w-auto bg-amber-600 text-white text-sm font-bold px-8 py-3 rounded-xl hover:bg-amber-700 transition">Salvar Dados</button></div>
                  <div className="bg-white p-6 md:p-8 rounded-2xl border border-gray-100 shadow-sm"><div className="flex items-center gap-2 mb-6 text-indigo-600"><IconCalendar /><h3 className="font-bold text-gray-900 text-sm uppercase tracking-wider">Agendar Consulta</h3></div><div className="space-y-4 mb-6"><div><label className="block text-xs font-bold text-gray-400 uppercase mb-2">Data e Hora (Ex: 15/10 às 14h)</label><input type="text" value={dataConsulta} onChange={(e)=>setDataConsulta(e.target.value)} className="w-full bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm focus:outline-indigo-500 transition" /></div><div><label className="block text-xs font-bold text-gray-400 uppercase mb-2">Link da Chamada (Meet/Zoom)</label><input type="text" value={linkConsulta} onChange={(e)=>setLinkConsulta(e.target.value)} placeholder="https://meet.google.com/..." className="w-full bg-gray-50 border border-gray-200 rounded-xl p-3 text-sm focus:outline-indigo-500 transition" /></div></div><button onClick={salvarNotasEAgenda} className="w-full md:w-auto bg-indigo-600 text-white text-sm font-bold px-8 py-3 rounded-xl hover:bg-indigo-700 transition">Agendar</button></div>
                </div>
              )}
            </div>
          )}

          {abaAtiva === 'feed' && (
            <div className="animate-fade-in max-w-4xl mx-auto no-print">
              <header className="mb-8"><h2 className="text-2xl md:text-3xl font-bold text-gray-900">Mural Educacional</h2></header>
              <form onSubmit={publicarNoFeed} className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm mb-8"><textarea value={novoPostTexto} onChange={(e) => setNovoPostTexto(e.target.value)} placeholder="Compartilhe com seus pacientes..." className="w-full h-32 bg-gray-50 border border-gray-200 rounded-xl p-4 text-sm focus:outline-[#3B4D43] resize-none mb-4 transition" /><div className="flex justify-end"><button type="submit" className="w-full md:w-auto bg-[#3B4D43] text-white text-sm font-bold px-8 py-3 rounded-xl hover:bg-[#2C3E35] transition">Publicar</button></div></form>
              <div className="space-y-4">
                {postsFeed.map(post => (<div key={post.id} className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm relative group flex justify-between items-start"><div className="flex-1"><span className="text-[10px] text-gray-500 font-bold uppercase mb-2 block">{post.autor}</span><p className="text-sm text-gray-700">{post.texto}</p></div><button onClick={() => excluirPost(post.id)} className="sm:opacity-0 group-hover:opacity-100 text-red-500 bg-red-50 p-2 rounded-lg hover:bg-red-500 hover:text-white transition-all"><IconTrash /></button></div>))}
              </div>
            </div>
          )}

          {abaAtiva === 'chat' && (
            <div className="h-[calc(100vh-10rem)] md:h-[calc(100vh-8rem)] flex flex-col md:flex-row gap-4 md:gap-6 animate-fade-in max-w-6xl mx-auto no-print">
              <div className={`w-full md:w-80 bg-white border border-gray-100 rounded-2xl overflow-hidden shadow-sm flex flex-col shrink-0 ${pacienteChatSelecionado ? 'hidden md:flex' : 'flex'}`}>
                <div className="p-4 border-b border-gray-100 bg-gray-50"><h3 className="font-bold text-sm text-gray-900 uppercase">Canais Privados</h3></div>
                <div className="flex-1 overflow-y-auto p-3 space-y-2">
                  {pacientes.map(p => (<button key={p.id} onClick={() => setPacienteChatSelecionado(p)} className={`w-full text-left p-3 rounded-xl transition-all duration-200 flex flex-col border ${pacienteChatSelecionado?.id === p.id ? 'bg-[#3B4D43] border-[#3B4D43] text-white' : 'bg-white border-transparent hover:bg-gray-50 text-gray-700'}`}><span className="font-bold text-sm truncate">{p.nome || "Sem Nome"}</span></button>))}
                </div>
              </div>
              <div className={`flex-1 bg-white border border-gray-100 rounded-2xl flex flex-col justify-between overflow-hidden shadow-sm ${pacienteChatSelecionado ? 'flex' : 'hidden md:flex'}`}>
                {pacienteChatSelecionado ? (
                  <><header className="p-4 border-b border-gray-100 bg-white flex items-center gap-3"><button onClick={() => setPacienteChatSelecionado(null)} className="md:hidden text-gray-400 bg-gray-50 p-2 rounded-lg"><IconX /></button><h4 className="font-bold text-gray-900 text-sm">{pacienteChatSelecionado.nome}</h4></header>
                    <div className="flex-1 p-4 md:p-6 overflow-y-auto bg-gray-50 space-y-4">
                      {mensagensChat.map(m => { const souEu = m.remetente === 'nutri'; return (<div key={m.id} className={`flex ${souEu ? 'justify-end' : 'justify-start'}`}><div className={`max-w-[85%] md:max-w-[70%] p-3.5 rounded-2xl text-sm shadow-sm ${souEu ? 'bg-[#3B4D43] text-white rounded-br-sm' : 'bg-white text-gray-700 border border-gray-100 rounded-bl-sm'}`}>{m.texto}</div></div>); })}
                    </div>
                    <form onSubmit={enviarMensagemChat} className="p-4 border-t border-gray-100 bg-white flex gap-3"><input type="text" value={novaMensagemTexto} onChange={(e) => setNovaMensagemTexto(e.target.value)} placeholder="Mensagem..." className="flex-1 bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-[#3B4D43]" /><button type="submit" className="bg-[#3B4D43] text-white px-5 py-3 rounded-xl font-bold">Enviar</button></form>
                  </>
                ) : <div className="flex-1 flex flex-col items-center justify-center p-8 text-gray-400"><div className="bg-gray-50 p-4 rounded-full mb-4"><IconMessage /></div><p className="text-sm">Selecione um paciente.</p></div>}
              </div>
            </div>
          )}
        </main>
      </div>
    </div>
  );
}
