import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth"; // 🚀 LINHA ADICIONADA AQUI

// Credenciais oficiais do seu projeto Nutri Life
const firebaseConfig = {
  apiKey: "AIzaSyDDonDjAPJzUQSDN6dBrG4p7fhI6YlqTSY",
  authDomain: "nutri-life-45b6c.firebaseapp.com",
  projectId: "nutri-life-45b6c",
  storageBucket: "nutri-life-45b6c.firebasestorage.app",
  messagingSenderId: "210549500065",
  appId: "1:210549500065:android:702ee7b33d41b046e968e0"
};

// Inicializa o Firebase
const app = initializeApp(firebaseConfig);

// Exporta o banco de dados Firestore para usarmos nas telas
export const db = getFirestore(app);

// 🚀 EXPORTA A AUTENTICAÇÃO PARA O LOGIN DO PAINEL WEB
export const auth = getAuth(app);
