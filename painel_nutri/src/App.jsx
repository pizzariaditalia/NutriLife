import React, { useState, useEffect } from 'react';
import { collection, doc, onSnapshot, updateDoc, addDoc, query, orderBy, limit, serverTimestamp } from 'firebase/firestore';
import { db } from './firebase';

export default function App() {
  const [abaAtiva, setAbaAtiva] = useState('pacientes'); 
  const [pacientes, setPacientes] = useState([]);
  const [carregando, setCarregando] = useState(true);
  
  const [pacienteSelecionado, setPacienteSelecionado] = useState(null);
  const [dadosDiario, setDadosDiario] = useState(null);
  const [historicoPesoReal, setHistoricoPesoReal] = useState([]);
  const [fichaClinica, setFichaClinica] = useState({});
  const [novaMetaCalorias, setNovaMetaCalorias] = useState(2000);
  const [novaMetaAgua, setNovaMetaAgua] = useState(2500);
  const [salvandoMeta, setSalvandoMeta] = useState(false);
  
  const [planoCafe, setPlanoCafe] = useState("");
  const [planoAlmoco, setPlanoAlmoco] = useState("");
  const [planoLanche, setPlanoLanche] = useState("");
  const [planoJantar, setPlanoJantar] = useState("");
  const [salvandoPlano, setSalvandoPlano] = useState(false);

  const [novoPostTexto, setNovoPostTexto] = useState("");
  const [postsFeed, setPostsFeed] = useState([]);
  const [publicandoPost, setPublicandoPost] = useState(false);

  const [pacienteChatSelecionado, setPacienteChatSelecionado] = useState(null);
  const [mensagensChat, setMensagensChat] = useState([]);
  const [novaMensagemTexto, setNovaMensagemTexto] = useState("");

  const dataHoje = new Date().toISOString().split('T')[0];

  useEffect(() => {
    return onSnapshot(collection(db, 'usuarios'), (snapshot) => {
      setPacientes(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setCarregando(false);
    });
  }, []);

  useEffect(() => {
    if (abaAtiva === 'feed') {
      const q = query(collection(db, 'feed'), orderBy('timestamp', 'desc'));
      return onSnapshot(q, (snapshot) => {
        setPostsFeed(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      });
    }
  }, [abaAtiva]);

  useEffect(() => {
    if (abaAtiva === 'chat' && pacienteChatSelecionado) {
      const q = query(collection(db, 'chats', pacienteChatSelecionado.id, 'mensagens'), orderBy('timestamp', 'asc'));
      return onSnapshot(q, (snapshot) => {
        setMensagensChat(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      });
    } else {
      setMensagensChat([]);
    }
  }, [abaAtiva, pacienteChatSelecionado]);

  useEffect(() => {
    if (!pacienteSelecionado) {
      setDadosDiario(null); setHistoricoPesoReal([]);
      setPlanoCafe(""); setPlanoAlmoco(""); setPlanoLanche(""); setPlanoJantar("");
      setFichaClinica({});
      return;
    }

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

    const q = query(collection(db, 'usuarios', pacienteSelecionado.id, 'historico_peso'), orderBy('timestamp', 'asc'), limit(5));
    const unsubPesos = onSnapshot(q, (snapshot) => {
      setHistoricoPesoReal(snapshot.docs.map(doc => doc.data()));
    });

    return () => { unsubDiario(); unsubPesos(); };
  }, [pacienteSelecionado]);

  const atualizarMetas = async (e) => {
    e.preventDefault();
    if (!pacienteSelecionado) return;
    setSalvandoMeta(true);
    try {
      await updateDoc(doc(db, 'usuarios', pacienteSelecionado.id, 'diario', dataHoje), {
        meta_calorias: Number(novaMetaCalorias), meta_agua: Number(novaMetaAgua)
      });
      alert("🎯 Metas numéricas guardadas e sincronizadas!");
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
      alert("🍏 Cardápio Clínico sincronizado com o app do paciente!");
    } catch (e) { alert("Erro ao salvar cardápio."); }
    finally { setSalvandoPlano(false); }
  };

  const publicarNoFeed = async (e) => {
    e.preventDefault();
    if (novoPostTexto.trim() === "") return;
    setPublicandoPost(true);
    try {
      await addDoc(collection(db, 'feed'), {
        autor: "Nutricionista Ana Silva 👑",
        texto: novoPostTexto.trim(),
        curtidas: [],
        timestamp: serverTimestamp()
      });
      setNovoPostTexto("");
      alert("📣 Conteúdo publicado com sucesso!");
    } catch (err) { alert("Erro ao publicar."); }
    finally { setPublicandoPost(false); }
  };

  const enviarMensagemChat = async (e) => {
    e.preventDefault();
    if (novaMensagemTexto.trim() === "" || !pacienteChatSelecionado) return;
    try {
      await addDoc(collection(db, 'chats', pacienteChatSelecionado.id, 'mensagens'), {
        texto: novaMensagemTexto.trim(),
        remetente: 'nutri',
        timestamp: serverTimestamp()
      });
      setNovaMensagemTexto("");
    } catch (err) { alert("Erro ao enviar mensagem."); }
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
      <aside className="w-64 bg-[#3B4D43] text-white flex flex-col justify-between p-6 shrink-0">
        <div>
          <div className="flex items-center gap-3 mb-8 cursor-pointer" onClick={() => { setAbaAtiva('pacientes'); setPacienteSelecionado(null); }}>
            <span className="text-2xl">🌿</span>
            <h1 className="text-xl font-bold tracking-wide">Nutri Life</h1>
          </div>
          <nav className="space-y-2">
            <button onClick={() => { setAbaAtiva('pacientes'); setPacienteSelecionado(null); }} className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-medium transition text-left ${abaAtiva === 'pacientes' ? 'bg-[#2C3E35] font-bold' : 'text-white/80 hover:bg-[#2C3E35]/50'}`}>
              <span>👥</span> Pacientes
            </button>
            <button onClick={() => setAbaAtiva('feed')} className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-medium transition text-left ${abaAtiva === 'feed' ? 'bg-[#2C3E35] font-bold' : 'text-white/80 hover:bg-[#2C3E35]/50'}`}>
              <span>📣</span> Gestão do Feed
            </button>
            <button onClick={() => { setAbaAtiva('chat'); setPacienteChatSelecionado(null); }} className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl font-medium transition text-left ${abaAtiva === 'chat' ? 'bg-[#2C3E35] font-bold' : 'text-white/80 hover:bg-[#2C3E35]/50'}`}>
              <span>💬</span> Consultório
            </button>
          </nav>
        </div>
        <div className="border-t border-white/10 pt-4 text-xs text-white/60">Painel Clínico v3.0 Web</div>
      </aside>

      <main className="flex-1 overflow-y-auto p-8 lg:p-12">
        
        {/* ABA 1: PACIENTES */}
        {abaAtiva === 'pacientes' && (!pacienteSelecionado ? (
          <div>
            <header className="mb-8">
              <h2 className="text-3xl font-bold text-gray-900">Pacientes Cadastrados</h2>
              <p className="text-gray-500 text-sm mt-1">Selecione um paciente para gerir dietas e metas.</p>
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
                    <tr><td colSpan="3" className="p-8 text-center text-gray-400">Buscando...</td></tr>
                  ) : pacientes.length === 0 ? (
                    <tr><td colSpan="3" className="p-8 text-center text-gray-400">Nenhum paciente cadastrado.</td></tr>
                  ) : pacientes.map((p) => (
                    <tr key={p.id} className="hover:bg-gray-50/50 transition">
                      <td className="p-4 pl-6">
                        <p className="font-bold text-gray-900">{p.nome || "Sem Nome"}</p>
                        <p className="text-xs text-gray-400">{p.email}</p>
                      </td>
                      <td className="p-4 text-gray-400 font-mono text-xs">{p.id}</td>
                      <td className="p-4 text-right pr-6">
                        <button onClick={() => setPacienteSelecionado(p)} className="text-[#3B4D43] font-bold text-xs bg-gray-100 hover:bg-[#3B4D43] hover:text-white px-4 py-2 rounded-xl transition">Prontuário →</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          </div>
        ) : (
          <div>
            <button onClick={() => setPacienteSelecionado(null)} className="text-sm font-bold text-[#3B4D43] hover:underline mb-4 block">← Voltar</button>
            <header className="mb-8">
              <span className="text-xs font-bold uppercase text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-md">Prontuário</span>
              <h2 className="text-3xl font-bold mt-2 text-gray-900">{pacienteSelecionado.nome || "Usuário de Teste"}</h2>
            </header>

            <div className="grid grid-cols-1 xl:grid-cols-3 gap-8">
              <div className="xl:col-span-2 space-y-6">
                
                {/* FICHA CLINICA */}
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-xs">
                  <h3 className="font-bold text-lg text-[#3B4D43] mb-4">Ficha de Anamnese</h3>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                    <div className="bg-gray-50 p-3 rounded-xl"><span className="text-xs text-gray-400 font-bold block">IDADE</span><span className="font-bold text-gray-800">{fichaClinica.idade}</span></div>
                    <div className="bg-gray-50 p-3 rounded-xl"><span className="text-xs text-gray-400 font-bold block">GÉNERO</span><span className="font-bold text-gray-800">{fichaClinica.genero}</span></div>
                    <div className="bg-gray-50 p-3 rounded-xl"><span className="text-xs text-gray-400 font-bold block">ALTURA</span><span className="font-bold text-gray-800">{fichaClinica.altura}m</span></div>
                    <div className="bg-gray-50 p-3 rounded-xl"><span className="text-xs text-gray-400 font-bold block">PESO INICIAL</span><span className="font-bold text-gray-800">{fichaClinica.peso_inicial}kg</span></div>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm mt-4">
                    <div className="border border-gray-100 p-3 rounded-xl"><span className="text-xs text-gray-400 font-bold block">🎯 OBJETIVO</span><span className="font-medium text-gray-900">{fichaClinica.objetivo}</span></div>
                    <div className="border border-gray-100 p-3 rounded-xl"><span className="text-xs text-gray-400 font-bold block">🏃 ATIVIDADE</span><span className="font-medium text-gray-900">{fichaClinica.nivel_atividade}</span></div>
                    <div className="border border-gray-100 p-3 rounded-xl"><span className="text-xs text-gray-400 font-bold block">🚫 RESTRIÇÃO</span><span className="font-bold text-red-600">{fichaClinica.restricao_alimentar}</span></div>
                  </div>
                </div>

                {/* METAS CONSUMO */}
                <div className="bg-white p-6 rounded-2xl border border-gray-100 grid grid-cols-2 gap-4 shadow-xs">
                  <div>
                    <span className="text-xs text-gray-400 font-bold uppercase">Calorias Hoje</span>
                    <p className="text-2xl font-bold text-[#3B4D43] mt-1">{dadosDiario?.calorias_consumidas || 0} <span className="text-sm font-normal text-gray-400">/ {dadosDiario?.meta_calorias || 2000} kcal</span></p>
                  </div>
                  <div>
                    <span className="text-xs text-gray-400 font-bold uppercase">Água Hoje</span>
                    <p className="text-2xl font-bold text-blue-600 mt-1">{dadosDiario?.agua_consumida || 0} <span className="text-sm font-normal text-gray-400">/ {dadosDiario?.meta_agua || 2500} ml</span></p>
                  </div>
                </div>

                {/* GRAFICO */}
                <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-xs">
                  <h3 className="font-bold text-lg text-[#3B4D43] mb-2">Evolução de Peso Dinâmica</h3>
                  <div className="relative w-full h-36 bg-gray-50/50 rounded-xl p-4 flex flex-col justify-between border border-gray-100">
                    {historicoPesoReal.length < 2 ? (
                      <div className="absolute inset-0 flex items-center justify-center text-sm text-gray-400">Aguardando mais registos...</div>
                    ) : (
                      <>
                        <svg className="absolute inset-0 w-full h-full p-8" viewBox="0 0 500 100" preserveAspectRatio="none">
                          <path d={construirCaminhoSVG()} fill="none" stroke="#3B4D43" strokeWidth="3" strokeLinecap="round"/>
                        </svg>
                        <div className="flex justify-between text-[11px] text-gray-400 font-bold mt-auto pt-4 z-10">
                          {historicoPesoReal.map((h, i) => (
                            <div key={i} className="text-center">
                              <p className="text-[#3B4D43] font-extrabold">{h.peso}kg</p>
                              <p className="mt-1 font-medium text-gray-400">{h.data ? h.data.split('-').slice(1).reverse().join('/') : ''}</p>
                            </div>
                          ))}
                        </div>
                      </>
                    )}
                  </div>
                </div>

                {/* PLANO ALIMENTAR */}
                <div className="bg-white p-6 rounded-2xl border border-gray-100 space-y-4 shadow-xs">
                  <div className="flex justify-between items-center">
                    <h3 className="font-bold text-lg text-[#3B4D43]">Plano Alimentar</h3>
                    <button onClick={salvarPlanoAlimentar} disabled={salvandoPlano} className="bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs px-4 py-2.5 rounded-xl transition">
                      {salvandoPlano ? "Sincronizando..." : "💾 Sincronizar"}
                    </button>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div><label className="block text-xs font-bold text-gray-500 mb-1">Café da Manhã</label><textarea value={planoCafe} onChange={(e) => setPlanoCafe(e.target.value)} className="w-full h-24 bg-[#F9F6F0] border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] resize-none" /></div>
                    <div><label className="block text-xs font-bold text-gray-500 mb-1">Almoço</label><textarea value={planoAlmoco} onChange={(e) => setPlanoAlmoco(e.target.value)} className="w-full h-24 bg-[#F9F6F0] border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] resize-none" /></div>
                    <div><label className="block text-xs font-bold text-gray-500 mb-1">Lanche</label><textarea value={planoLanche} onChange={(e) => setPlanoLanche(e.target.value)} className="w-full h-24 bg-[#F9F6F0] border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] resize-none" /></div>
                    <div><label className="block text-xs font-bold text-gray-500 mb-1">Jantar</label><textarea value={planoJantar} onChange={(e) => setPlanoJantar(e.target.value)} className="w-full h-24 bg-[#F9F6F0] border border-gray-200 rounded-xl p-3 text-sm focus:outline-[#3B4D43] resize-none" /></div>
                  </div>
                </div>
              </div>

              {/* ATUALIZAR METAS NUMERICAS */}
              <div className="bg-white p-6 rounded-2xl border border-gray-100 h-fit shadow-xs">
                <h3 className="font-bold text-lg text-[#3B4D43] mb-1">Metas Clínicas</h3>
                <form onSubmit={atualizarMetas} className="space-y-4 mt-4">
                  <div>
                    <label className="block text-xs font-bold uppercase text-gray-500 mb-1">Meta Calórica (kcal)</label>
                    <input type="number" value={novaMetaCalorias} onChange={(e) => setNovaMetaCalorias(e.target.value)} className="w-full bg-[#F9F6F0] border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-[#3B4D43]" required />
                  </div>
                  <div>
                    <label className="block text-xs font-bold uppercase text-gray-500 mb-1">Meta Água (ml)</label>
                    <input type="number" value={novaMetaAgua} onChange={(e) => setNovaMetaAgua(e.target.value)} className="w-full bg-[#F9F6F0] border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-[#3B4D43]" required />
                  </div>
                  <button type="submit" disabled={salvandoMeta} className="w-full bg-[#3B4D43] text-white py-3 rounded-xl font-bold text-sm shadow-sm hover:bg-[#2C3E35] transition">
                    Atualizar Parâmetros
                  </button>
                </form>
              </div>
            </div>
          </div>
        ))}

        {/* ABA 2: FEED */}
        {abaAtiva === 'feed' && (
          <div className="max-w-4xl">
            <header className="mb-8">
              <h2 className="text-3xl font-bold text-gray-900">Gestão do Feed</h2>
              <p className="text-gray-500 text-sm mt-1">Publique conteúdos e dicas. Todos os pacientes terão acesso em tempo real.</p>
            </header>
            <form onSubmit={publicarNoFeed} className="bg-white p-6 rounded-2xl border border-gray-100 shadow-xs mb-8">
              <label className="block text-xs font-bold uppercase text-gray-400 mb-2">Nova Publicação</label>
              <textarea 
                value={novoPostTexto} 
                onChange={(e) => setNovoPostTexto(e.target.value)}
                placeholder="Escreva sua dica..." 
                className="w-full h-32 bg-[#F9F6F0] border border-gray-200 rounded-xl p-4 text-sm focus:outline-[#3B4D43] resize-none mb-4"
              />
              <div className="text-right">
                <button type="submit" disabled={publicandoPost} className="bg-[#3B4D43] text-white font-bold text-sm px-6 py-2.5 rounded-xl hover:bg-[#2C3E35] transition">
                  {publicandoPost ? "Publicando..." : "📣 Publicar Conteúdo"}
                </button>
              </div>
            </form>
            <h3 className="font-bold text-xl text-gray-900 mb-4">Postagens Anteriores</h3>
            <div className="space-y-4">
              {postsFeed.length === 0 ? (
                <p className="text-gray-400 text-sm italic">Nenhum post publicado na nuvem.</p>
              ) : postsFeed.map(post => (
                <div key={post.id} className="bg-white p-5 rounded-2xl border border-gray-100 shadow-xs">
                  <div className="flex justify-between text-xs text-gray-400 font-bold mb-2">
                    <span>{post.autor}</span>
                    <span>❤️ {post.curtidas?.length || 0} Likes</span>
                  </div>
                  <p className="text-sm text-gray-800 leading-relaxed">{post.texto}</p>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ABA 3: CHAT */}
        {abaAtiva === 'chat' && (
          <div className="h-[calc(100vh-6rem)] flex gap-6">
            <div className="w-80 bg-white border border-gray-100 rounded-2xl p-4 overflow-y-auto shadow-xs">
              <h3 className="font-bold text-md text-gray-900 mb-2 px-2">Canais Ativos</h3>
              {pacientes.map(p => (
                <button 
                  key={p.id} 
                  onClick={() => setPacienteChatSelecionado(p)}
                  className={`w-full text-left p-3 rounded-xl transition flex flex-col mb-2 ${pacienteChatSelecionado?.id === p.id ? 'bg-[#3B4D43] text-white' : 'hover:bg-gray-50 text-gray-700'}`}
                >
                  <span className="font-bold text-sm">{p.nome || "Sem Nome"}</span>
                  <span className={`text-xs mt-0.5 ${pacienteChatSelecionado?.id === p.id ? 'text-white/60' : 'text-gray-400'}`}>Abrir chat</span>
                </button>
              ))}
            </div>
            <div className="flex-1 bg-white border border-gray-100 rounded-2xl flex flex-col justify-between overflow-hidden shadow-xs">
              {pacienteChatSelecionado ? (
                <>
                  <header className="p-4 border-b border-gray-100 bg-gray-50/50">
                    <h4 className="font-bold text-gray-900 text-sm">Canal com: {pacienteChatSelecionado.nome}</h4>
                  </header>
                  <div className="flex-1 p-4 overflow-y-auto bg-gray-50/30 space-y-3">
                    {mensagensChat.length === 0 ? (
                      <p className="text-center text-gray-400 text-xs italic pt-8">Sem histórico.</p>
                    ) : mensagensChat.map(m => {
                      const souEu = m.remetente === 'nutri';
                      return (
                        <div key={m.id} className={`flex ${souEu ? 'justify-end' : 'justify-start'}`}>
                          <div className={`max-w-md p-3 rounded-2xl text-sm ${souEu ? 'bg-[#3B4D43] text-white rounded-br-none' : 'bg-white text-gray-800 border border-gray-100 rounded-bl-none'}`}>
                            {m.texto}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                  <form onSubmit={enviarMensagemChat} className="p-4 border-t border-gray-100 flex gap-3 items-center">
                    <input 
                      type="text" 
                      value={novaMensagemTexto}
                      onChange={(e) => setNovaMensagemTexto(e.target.value)}
                      placeholder="Digite a mensagem..." 
                      className="flex-1 bg-[#F9F6F0] border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-[#3B4D43]"
                    />
                    <button type="submit" className="bg-[#3B4D43] text-white font-bold text-xs px-5 py-3 rounded-xl hover:bg-[#2C3E35] transition">Enviar 📩</button>
                  </form>
                </>
              ) : (
                <div className="flex-1 flex items-center justify-center p-8 text-gray-400"><p>Selecione um paciente.</p></div>
              )}
            </div>
          </div>
        )}

      </main>
    </div>
  );
}
