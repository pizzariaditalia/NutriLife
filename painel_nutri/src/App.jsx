import React, { useState, useEffect } from 'react';
import { collection, onSnapshot } from 'firebase/firestore';
import { db } from './firebase';

export default function App() {
  const [pacientes, setPacientes] = useState([]);
  const [carregando, setCarregando] = useState(true);

  // 🔥 ESCUTADOR EM TEMPO REAL: Busca os pacientes direto da coleção 'usuarios' do Firebase
  useEffect(() => {
    const colecaoRef = collection(db, 'usuarios');
    
    const fecharConexao = onSnapshot(colecaoRef, (snapshot) => {
      const listaPacientes = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setPacientes(listaPacientes);
      setCarregando(false);
    }, (erro) => {
      console.error("Erro ao buscar pacientes: ", erro);
      setCarregando(false);
    });

    return () => fecharConexao();
  }, []);

  return (
    <div class="flex h-screen overflow-hidden">
      
      <aside class="w-64 bg-[#3B4D43] text-white flex flex-col justify-between p-6">
        <div>
          <div class="flex items-center gap-3 mb-8">
            <span class="text-2xl">🌿</span>
            <h1 class="text-xl font-bold tracking-wide">Nutri Life</h1>
          </div>
          <nav class="space-y-2">
            <a href="#" class="flex items-center gap-3 bg-[#2C3E35] px-4 py-3 rounded-xl font-medium transition">
              <span>📊</span> Dashboard
            </a>
            <a href="#" class="flex items-center gap-3 text-white/80 hover:bg-[#2C3E35]/50 px-4 py-3 rounded-xl font-medium transition">
              <span>👥</span> Pacientes
            </a>
          </nav>
        </div>
        <div class="border-t border-white/10 pt-4 text-xs text-white/60">
          Painel Clínico v1.0
        </div>
      </aside>

      <main class="flex-1 overflow-y-auto p-8 lg:p-12">
        
        <header class="flex justify-between items-center mb-8">
          <div>
            <h2 class="text-3xl font-bold">Olá, Doutora!</h2>
            <p class="text-gray-500 text-sm mt-1">Aqui está o andamento dos seus pacientes em tempo real.</p>
          </div>
        </header>

        <section class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
          <div class="bg-white p-6 rounded-2xl shadow-xs border border-gray-100">
            <span class="text-gray-400 text-xs font-bold uppercase tracking-wider">Pacientes Cadastrados</span>
            <p class="text-3xl font-bold mt-2 text-[#3B4D43]">{carregando ? "..." : pacientes.length}</p>
          </div>
          <div class="bg-white p-6 rounded-2xl shadow-xs border border-gray-100">
            <span class="text-gray-400 text-xs font-bold uppercase tracking-wider">Acessos Hoje</span>
            <p class="text-3xl font-bold mt-2 text-emerald-600">{carregando ? "..." : pacientes.length > 0 ? "1" : "0"}</p>
          </div>
          <div class="bg-white p-6 rounded-2xl shadow-xs border border-gray-100">
            <span class="text-gray-400 text-xs font-bold uppercase tracking-wider">Sincronização</span>
            <p class="text-sm font-bold mt-4 text-emerald-500 flex items-center gap-1.5">
              <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span> Conectado à Nuvem
            </p>
          </div>
        </section>

        <section class="bg-white rounded-2xl shadow-xs border border-gray-100 overflow-hidden">
          <div class="p-6 border-b border-gray-50">
            <h3 class="font-bold text-lg">Seus Pacientes</h3>
          </div>
          <div class="overflow-x-auto">
            {carregando ? (
              <div class="p-8 text-center text-gray-400">Carregando dados da nuvem...</div>
            ) : pacientes.length === 0 ? (
              <div class="p-8 text-center text-gray-400">Nenhum paciente cadastrado no aplicativo ainda.</div>
            ) : (
              <table class="w-full text-left border-collapse">
                <thead>
                  <tr class="bg-gray-50/70 border-b border-gray-100 text-gray-400 text-xs uppercase font-bold tracking-wider">
                    <th class="p-4 pl-6">Paciente</th>
                    <th class="p-4">ID de Registro</th>
                    <th class="p-4 text-center">Ações</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-50 text-sm">
                  {pacientes.map((paciente) => (
                    <tr key={paciente.id} class="hover:bg-gray-50/50 transition">
                      <td class="p-4 pl-6">
                        <p class="font-bold text-gray-900">{paciente.nome || "Usuário Sem Nome"}</p>
                        <p class="text-xs text-gray-400">{paciente.email || "E-mail não informado"}</p>
                      </td>
                      <td class="p-4 text-gray-500 font-mono text-xs">{paciente.id}</td>
                      <td class="p-4 text-center">
                        <button class="text-[#3B4D43] hover:text-[#2C3E35] font-bold text-xs bg-gray-100 hover:bg-gray-200 px-3 py-1.5 rounded-lg transition">
                          Visualizar Diário
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </section>

      </main>
    </div>
  );
}
