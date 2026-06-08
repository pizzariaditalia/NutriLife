import React, { useState } from 'react';

export default function App() {
  // Simulando uma lista de pacientes direto no estado para validação visual do layout
  const [pacientes] = useState([
    { id: 1, nome: "Bruno Tenório", email: "brunotendr@gmail.com", status: "Dieta Ativa", kcal: "2.000 kcal", progresso: "75%" },
    { id: 2, nome: "Glória Maria", email: "gloria@exemplo.com", status: "Aguardando Ajuste", kcal: "1.600 kcal", progresso: "40%" },
    { id: 3, nome: "Carlos Henrique", email: "carlos@exemplo.com", status: "Sem Dieta", kcal: "--", progresso: "0%" }
  ]);

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
            <a href="#" class="flex items-center gap-3 text-white/80 hover:bg-[#2C3E35]/50 px-4 py-3 rounded-xl font-medium transition">
              <span>🍎</span> Planos Alimentares
            </a>
          </nav>
        </div>
        <div class="border-t border-white/10 pt-4 text-xs text-white/60">
          Clínica Logada: Dra. Nutricionista
        </div>
      </aside>

      <main class="flex-1 overflow-y-auto p-8 lg:p-12">
        
        <header class="flex justify-between items-center mb-8">
          <div>
            <h2 class="text-3xl font-bold">Olá, Doutora!</h2>
            <p class="text-gray-500 text-sm mt-1">Aqui está o andamento dos seus pacientes hoje.</p>
          </div>
          <button class="bg-[#3B4D43] text-white px-5 py-2.5 rounded-xl font-semibold shadow-sm hover:bg-[#2C3E35] transition">
            + Novo Paciente
          </button>
        </header>

        <section class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
          <div class="bg-white p-6 rounded-2xl shadow-xs border border-gray-100">
            <span class="text-gray-400 text-xs font-bold uppercase tracking-wider">Total de Pacientes</span>
            <p class="text-3xl font-bold mt-2 text-[#3B4D43]">{pacientes.length}</p>
          </div>
          <div class="bg-white p-6 rounded-2xl shadow-xs border border-gray-100">
            <span class="text-gray-400 text-xs font-bold uppercase tracking-wider">Dietas Ativas</span>
            <p class="text-3xl font-bold mt-2 text-emerald-600">2</p>
          </div>
          <div class="bg-white p-6 rounded-2xl shadow-xs border border-gray-100">
            <span class="text-gray-400 text-xs font-bold uppercase tracking-wider">Alertas Pendentes</span>
            <p class="text-3xl font-bold mt-2 text-amber-500">1</p>
          </div>
        </section>

        <section class="bg-white rounded-2xl shadow-xs border border-gray-100 overflow-hidden">
          <div class="p-6 border-b border-gray-50 flex justify-between items-center">
            <h3 class="font-bold text-lg">Seus Pacientes Recentes</h3>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="bg-gray-50/70 border-b border-gray-100 text-gray-400 text-xs uppercase font-bold tracking-wider">
                  <th class="p-4 pl-6">Nome</th>
                  <th class="p-4">Status</th>
                  <th class="p-4">Meta Diária</th>
                  <th class="p-4">Adesão Recente</th>
                  <th class="p-4 text-center">Ações</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-50 text-sm">
                {pacientes.map((paciente) => (
                  <tr key={paciente.id} class="hover:bg-gray-50/50 transition">
                    <td class="p-4 pl-6">
                      <p class="font-bold text-gray-900">{paciente.nome}</p>
                      <p class="text-xs text-gray-400">{paciente.email}</p>
                    </td>
                    <td class="p-4">
                      <span class={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${
                        paciente.status === "Dieta Ativa" ? "bg-emerald-50 text-emerald-700" :
                        paciente.status === "Aguardando Ajuste" ? "bg-amber-50 text-amber-700" :
                        "bg-gray-100 text-gray-700"
                      }`}>
                        {paciente.status}
                      </span>
                    </td>
                    <td class="p-4 text-gray-600 font-medium">{paciente.kcal}</td>
                    <td class="p-4">
                      <div class="flex items-center gap-2">
                        <div class="w-24 bg-gray-100 h-2 rounded-full overflow-hidden">
                          <div class="bg-[#3B4D43] h-full" style={{ width: paciente.progresso }}></div>
                        </div>
                        <span class="text-xs text-gray-500 font-bold">{paciente.progresso}</span>
                      </div>
                    </td>
                    <td class="p-4 text-center">
                      <button class="text-[#3B4D43] hover:text-[#2C3E35] font-bold text-xs bg-gray-100 hover:bg-gray-200 px-3 py-1.5 rounded-lg transition">
                        Montar Cardápio
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

      </main>
    </div>
  );
}
