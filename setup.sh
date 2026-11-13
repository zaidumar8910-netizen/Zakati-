#!/bin/bash
set -e
APP_DIR="Zakati-Pro-App"
mkdir -p "$`APP_DIR"/{src/{lib,context,hooks,features/{premium,zakat,calculator,purification}},.github/workflows}
1. package.json
cat << 'EOF' > "`$APP_DIR/package.json"
{
"name": "zakati-halal-calc-pro",
"private": true,
"version": "1.0.0",
"type": "module",
"scripts": {
"dev": "vite",
"build": "tsc && vite build",
"preview": "vite preview",
"cap:sync": "npm run build && npx cap sync",
"cap:android": "npx cap open android"
},
"dependencies": {
"@capacitor/android": "^6.0.0",
"@capacitor/core": "^6.0.0",
"@supabase/supabase-js": "^2.45.0",
"lucide-react": "^0.453.0",
"react": "^18.3.1",
"react-dom": "^18.3.1"
},
"devDependencies": {
"@capacitor/cli": "^6.0.0",
"@types/react": "^18.3.11",
"@types/react-dom": "^18.3.1",
"@vitejs/plugin-react": "^4.3.2",
"autoprefixer": "^10.4.20",
"postcss": "^8.4.47",
"tailwindcss": "^3.4.13",
"typescript": "^5.6.2",
"vite": "^5.4.8"
}
}
EOF
2. capacitor.config.ts
cat << 'EOF' > "$`APP_DIR/capacitor.config.ts"
import { CapacitorConfig } from '@capacitor/cli';
const config: CapacitorConfig = {
appId: 'com.halalcalcpro.app',
appName: 'Zakati Pro',
webDir: 'dist',
server: {
androidScheme: 'https'
}
};
export default config;
EOF
3. GitHub Actions Automatic Android APK Workflow
cat << 'EOF' > "`$APP_DIR/.github/workflows/build-android.yml"
name: Build Android APK
on:
push:
branches: [ main ]
workflow_dispatch:
jobs:
build:
runs-on: ubuntu-latest
steps:
- uses: actions/checkout@v4
- name: Set up Node.js
uses: actions/setup-node@v4
with:
node-version: '20'
- name: Install dependencies
run: npm install
- name: Build web app
run: npm run build
- name: Set up JDK 17
uses: actions/setup-java@v4
with:
java-version: '17'
distribution: 'temurin'
- name: Initialize & Sync Capacitor Android
run: npx cap sync android || npx cap add android
- name: Build Debug APK
run: |
cd android
chmod +x gradlew
./gradlew assembleDebug
- name: Upload APK Artifact
uses: actions/upload-artifact@v4
with:
name: zakati-pro-android-apk
path: android/app/build/outputs/apk/debug/app-debug.apk
EOF
4. index.html
cat << 'EOF' > "$`APP_DIR/index.html"

Zakati Pro
 EOF 
5. tsconfig.json & vite.config.ts & tailwind/postcss
cat << 'EOF' > "`$APP_DIR/tsconfig.json"
{
"compilerOptions": {
"target": "ES2020",
"useDefineForClassFields": true,
"lib": ["ES2020", "DOM", "DOM.Iterable"],
"module": "ESNext",
"skipLibCheck": true,
"moduleResolution": "bundler",
"allowImportingTsExtensions": true,
"isolatedModules": true,
"moduleDetection": "force",
"noEmit": true,
"jsx": "react-jsx",
"strict": true
},
"include": ["src"]
}
EOF
cat << 'EOF' > "$`APP_DIR/vite.config.ts"
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({
plugins: [react()],
build: { outDir: 'dist' }
});
EOF
cat << 'EOF' > "`$APP_DIR/tailwind.config.js"
export default {
content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
theme: { extend: {} },
plugins: []
};
EOF
cat << 'EOF' > "$`APP_DIR/postcss.config.js"
export default {
plugins: { tailwindcss: {}, autoprefixer: {} }
};
EOF
6. src/index.css & src/main.tsx
cat << 'EOF' > "`$APP_DIR/src/index.css"
@tailwind base;
@tailwind components;
@tailwind utilities;
body {
padding-top: env(safe-area-inset-top);
padding-bottom: env(safe-area-inset-bottom);
}
EOF
cat << 'EOF' > "$`APP_DIR/src/main.tsx"
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';
ReactDOM.createRoot(document.getElementById('root')!).render(
<React.StrictMode>

</React.StrictMode>
);
EOF
7. src/lib/supabase.ts
cat << 'EOF' > "`$APP_DIR/src/lib/supabase.ts"
import { createClient } from '@supabase/supabase-js';
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://placeholder.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'placeholder-key';
export const supabase = createClient(supabaseUrl, supabaseAnonKey);
EOF
8. src/context/AuthProvider.tsx (Google Sign-In)
cat << 'EOF' > "$`APP_DIR/src/context/AuthProvider.tsx"
import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
interface AuthContextType {
user: User | null;
session: Session | null;
loading: boolean;
signInWithGoogle: () => Promise;
signOut: () => Promise;
}
const AuthContext = createContext({
user: null,
session: null,
loading: true,
signInWithGoogle: async () => {},
signOut: async () => {},
});
export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
const [user, setUser] = useState<User | null>(null);
const [session, setSession] = useState<Session | null>(null);
const [loading, setLoading] = useState(true);
useEffect(() => {
supabase.auth.getSession().then(({ data: { session } }) => {
setSession(session);
setUser(session?.user ?? null);
setLoading(false);
});
const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
setSession(session);
setUser(session?.user ?? null);
setLoading(false);
});
return () => subscription.unsubscribe();
}, []);
const signInWithGoogle = async () => {
const { error } = await supabase.auth.signInWithOAuth({
provider: 'google',
options: { redirectTo: window.location.origin },
});
if (error) throw error;
};
const signOut = async () => {
await supabase.auth.signOut();
};
return (
<AuthContext.Provider value={{ user, session, loading, signInWithGoogle, signOut }}>
{children}
</AuthContext.Provider>
);
};
export const useAuth = () => useContext(AuthContext);
EOF
9. src/hooks/useSubscription.ts (7-Day Free Trial)
cat << 'EOF' > "`$APP_DIR/src/hooks/useSubscription.ts"
import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthProvider';
import { supabase } from '../lib/supabase';
export interface SubscriptionState {
isSubscribed: boolean;
isTrialActive: boolean;
trialDaysLeft: number;
loading: boolean;
plan: 'free' | 'monthly' | 'yearly' | 'trial';
}
export function useSubscription(): SubscriptionState {
const { user } = useAuth();
const [state, setState] = useState({
isSubscribed: false,
isTrialActive: false,
trialDaysLeft: 0,
loading: true,
plan: 'free',
});
useEffect(() => {
async function checkSubscription() {
if (!user) {
setState({ isSubscribed: false, isTrialActive: false, trialDaysLeft: 0, loading: false, plan: 'free' });
return;
}
try {
const createdAt = new Date(user.created_at || Date.now());
const diffDays = Math.floor((Date.now() - createdAt.getTime()) / (1000 * 60 * 60 * 24));
const trialDaysLeft = Math.max(0, 7 - diffDays);
const isTrialActive = trialDaysLeft > 0;
const { data: subData } = await supabase
.from('subscriptions')
.select('status, plan_type')
.eq('user_id', user.id)
.eq('status', 'active')
.maybeSingle();
const isSubscribed = !!subData;
const activePlan = isSubscribed ? (subData.plan_type as 'monthly' | 'yearly') : isTrialActive ? 'trial' : 'free';
setState({
isSubscribed: isSubscribed || isTrialActive,
isTrialActive,
trialDaysLeft,
loading: false,
plan: activePlan,
});
} catch {
setState((s) => ({ ...s, loading: false }));
}
}
checkSubscription();
}, [user]);
return state;
}
EOF
10. src/features/premium/SubscribeModal.tsx
cat << 'EOF' > "$`APP_DIR/src/features/premium/SubscribeModal.tsx"
import React from 'react';
import { X, CheckCircle, Sparkles, Clock } from 'lucide-react';
import { useSubscription } from '../../hooks/useSubscription';
export const SubscribeModal: React.FC<{ isOpen: boolean; onClose: () => void }> = ({ isOpen, onClose }) => {
const { isTrialActive, trialDaysLeft } = useSubscription();
if (!isOpen) return null;
return (

<button onClick={onClose} className="absolute right-4 top-4 text-slate-400 hover:text-slate-100">

Premium Suite
Unlock Full Halal Financial Suite

Multi-asset Zakat management, stock dividend purification, saved history, and itemized CSV reports.

{isTrialActive && (

7-Day Free Trial Active

{trialDaysLeft} days remaining on your complimentary trial.

)}

{[
'Multi-Asset Zakat Management & Live Nisab Tracking',
'Stock Dividend Purification & Cleansing Calculator',
'Saved Zakat History & Itemized CSV Export',
'Zero Ads & Secure Cloud Sync'
 ].map((feature, idx) => (
<div key={idx} className="flex items-center gap-3 text-sm text-slate-300">

{feature}

))}

<button
onClick={() => alert('Redirecting to Monthly Checkout ($4.99/mo)...')} className="rounded-xl bg-emerald-600 hover:bg-emerald-500 py-3 font-semibold text-white text-sm" > Monthly ($4.99/mo)

<button
onClick={() => alert('Redirecting to Yearly Checkout ($25/yr)...')} className="rounded-xl bg-slate-800 hover:bg-slate-700 border border-emerald-500/40 py-3 font-semibold text-emerald-300 text-sm" > Yearly ($25/yr)

);
};
EOF
11. src/features/zakat/ZakatEstimator.tsx
cat << 'EOF' > "`$APP_DIR/src/features/zakat/ZakatEstimator.tsx"
import React, { useState } from 'react';
import { Download, History, ShieldCheck, Coins } from 'lucide-react';
import { useSubscription } from '../../hooks/useSubscription';
interface ZakatRecord {
id: string;
date: string;
netAssets: number;
zakatDue: number;
standard: 'Gold' | 'Silver';
}
export const ZakatEstimator: React.FC<{ onOpenUpgrade: () => void }> = ({ onOpenUpgrade }) => {
const { isSubscribed } = useSubscription();
const [cash, setCash] = useState('');
const [goldGrams, setGoldGrams] = useState('');
const [silverGrams, setSilverGrams] = useState('');
const [investments, setInvestments] = useState('');
const [liabilities, setLiabilities] = useState('');
const [standard, setStandard] = useState<'Gold' | 'Silver'>('Gold');
const [history, setHistory] = useState<ZakatRecord[]>([]);
const goldPricePerGram = 85.5;
const silverPricePerGram = 1.05;
const nisabThreshold = standard === 'Gold' ? 87.48 * goldPricePerGram : 612.36 * silverPricePerGram;
const totalAssets =
(parseFloat(cash) || 0) +
(parseFloat(goldGrams) || 0) * goldPricePerGram +
(parseFloat(silverGrams) || 0) * silverPricePerGram +
(parseFloat(investments) || 0);
const netWealth = Math.max(0, totalAssets - (parseFloat(liabilities) || 0));
const isEligible = netWealth >= nisabThreshold;
const zakatDue = isEligible ? netWealth * 0.025 : 0;
const handleSaveRecord = () => {
if (!isSubscribed) return onOpenUpgrade();
setHistory([{ id: Date.now().toString(), date: new Date().toLocaleDateString(), netAssets: netWealth, zakatDue, standard }, ...history]);
};
const handleExportCSV = () => {
if (!isSubscribed) return onOpenUpgrade();
const rows = [
['Date', 'Standard', 'Net Wealth (USD)', 'Zakat Due (2.5%)'],
[new Date().toLocaleDateString(), standard, netWealth.toFixed(2), zakatDue.toFixed(2)]
];
const encodedUri = encodeURI('data:text/csv;charset=utf-8,' + rows.map((e) => e.join(',')).join('\n'));
const link = document.createElement('a');
link.setAttribute('href', encodedUri);
link.setAttribute('download', zakati-report-${Date.now()}.csv`);
document.body.appendChild(link);
link.click();
document.body.removeChild(link);
};
return (

Multi-Asset Zakat Calculator

Live Nisab ({standard}): ${nisabThreshold.toFixed(2)}</span> </p> </div> <div className="flex rounded-xl bg-slate-950 p-1 border border-slate-800"> {(['Gold', 'Silver'] as const).map((s) => ( <button key={s} onClick={() => setStandard(s)} className={px-3 py-1.5 rounded-lg text-xs font-medium ${standard === s ? 'bg-emerald-600 text-white' : 'text-slate-400'}}
>
{s} Nisab

))}

<input type="number" value={cash} onChange={(e) => setCash(e.target.value)} placeholder="Cash & Bank Balances ($)" className="rounded-xl bg-slate-950 border border-slate-800 px-4 py-2.5 text-sm" /> <input type="number" value={goldGrams} onChange={(e) => setGoldGrams(e.target.value)} placeholder="24K Gold Weight (Grams)" className="rounded-xl bg-slate-950 border border-slate-800 px-4 py-2.5 text-sm" /> <input type="number" value={silverGrams} onChange={(e) => setSilverGrams(e.target.value)} placeholder="Pure Silver Weight (Grams)" className="rounded-xl bg-slate-950 border border-slate-800 px-4 py-2.5 text-sm" /> <input type="number" value={investments} onChange={(e) => setInvestments(e.target.value)} placeholder="Halal Stocks & Inventory ($)" className="rounded-xl bg-slate-950 border border-slate-800 px-4 py-2.5 text-sm" />
<input type="number" value={liabilities} onChange={(e) => setLiabilities(e.target.value)} placeholder="Deductible Liabilities (`$)" className="md:col-span-2 rounded-xl bg-slate-950 border border-slate-800 px-4 py-2.5 text-sm" />

Net Zakatable Wealth: {zakatDue.toFixed(2)}

<button onClick={handleSaveRecord} className="flex items-center gap-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 px-4 py-2.5 text-xs font-semibold text-white">
 Save

<button onClick={handleExportCSV} className="flex items-center gap-2 rounded-xl bg-slate-800 hover:bg-slate-700 px-4 py-2.5 text-xs font-semibold text-slate-200">
 Export CSV

{history.length > 0 && (

 Saved Zakat History

{history.map((item) => (
<div key={item.id} className="flex justify-between rounded-xl bg-slate-950 px-4 py-3 text-xs border border-slate-800">
{item.date} ({item.standard})
Due: $`{item.zakatDue.toFixed(2)}

))}

)}

);
};
EOF
12. src/features/calculator/StandardCalculator.tsx
cat << 'EOF' > "`$APP_DIR/src/features/calculator/StandardCalculator.tsx"
import React, { useState } from 'react';
import { Delete } from 'lucide-react';
export const StandardCalculator: React.FC = () => {
const [display, setDisplay] = useState('0');
const [history, setHistory] = useState<string[]>([]);
const handlePress = (val: string) => {
if (val === 'C') return setDisplay('0');
if (val === 'DEL') return setDisplay((p) => (p.length > 1 ? p.slice(0, -1) : '0'));
if (val === '=') {
try {
const sanitized = display.replace(/×/g, '*').replace(/÷/g, '/');
const result = Function("use strict"; return (${sanitized}))(); const formatted = Number.isFinite(result) ? String(Number(result.toFixed(8))) : 'Error'; setHistory((p) => [``${display} = ${formatted}`, ...p.slice(0, 9)]);
setDisplay(formatted);
} catch {
setDisplay('Error');
}
return;
}
setDisplay((p) => (p === '0' || p === 'Error' ? val : p + val));
};
const buttons = ['C', 'DEL', '%', '÷', '7', '8', '9', '×', '4', '5', '6', '-', '1', '2', '3', '+', '0', '.', '='];
return (

{display}

{buttons.map((btn) => (
<button
key={btn}
onClick={() => handlePress(btn)}
className={py-4 rounded-xl font-semibold text-lg${
btn === '='
? 'col-span-2 bg-emerald-600 text-white'
: ['÷', '×', '-', '+', '%'].includes(btn)
? 'bg-slate-800 text-emerald-400'
: btn === 'C' || btn === 'DEL'
? 'bg-rose-500/10 text-rose-400'
: 'bg-slate-950 text-slate-200 border border-slate-800'
}`}
>
{btn === 'DEL' ?  : btn}

))}

Calculation Tape

• 
• {history.map((entry, idx) => (
• <li key={idx} className="p-2.5 rounded-lg bg-slate-950 border border-slate-800">{entry}
• ))}

);
};
EOF
13. src/features/purification/StockPurification.tsx
cat << 'EOF' > "$`APP_DIR/src/features/purification/StockPurification.tsx"
import React, { useState } from 'react';
import { ShieldAlert, Sparkles } from 'lucide-react';
import { useSubscription } from '../../hooks/useSubscription';
export const StockPurification: React.FC<{ onOpenUpgrade: () => void }> = ({ onOpenUpgrade }) => {
const { isSubscribed } = useSubscription();
const [dividends, setDividends] = useState('');
const [impermissibleRatio, setImpermissibleRatio] = useState('3.5');
const divAmount = parseFloat(dividends) || 0;
const ratio = parseFloat(impermissibleRatio) || 0;
const purificationAmount = divAmount * (ratio / 100);
const pureDividend = Math.max(0, divAmount - purificationAmount);
return (

Stock Dividend Purification

{!isSubscribed && (
<button onClick={onOpenUpgrade} className="flex items-center gap-1.5 rounded-xl bg-emerald-600/20 border border-emerald-500/30 px-3 py-1.5 text-xs font-semibold text-emerald-300">
 Pro Feature

)}

<input type="number" value={dividends} onChange={(e) => setDividends(e.target.value)} placeholder="Total Dividends Received ($)" className="rounded-xl bg-slate-950 border border-slate-800 px-4 py-2.5 text-sm" /> <input type="number" value={impermissibleRatio} onChange={(e) => setImpermissibleRatio(e.target.value)} placeholder="Non-Compliant Revenue Ratio (%)" className="rounded-xl bg-slate-950 border border-slate-800 px-4 py-2.5 text-sm" /> </div> <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-4"> <div className="rounded-xl bg-slate-950 border border-slate-800 p-4"> <p className="text-xs text-slate-400">Charity Purification Amount</p> <p className="text-2xl font-bold text-amber-400 mt-1">${purificationAmount.toFixed(2)}

Net Halal Dividend Kept

`${pureDividend.toFixed(2)}

);
};
EOF
14. src/App.tsx
cat << 'EOF' > "$`APP_DIR/src/App.tsx"
import React, { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthProvider';
import { useSubscription } from './hooks/useSubscription';
import { ZakatEstimator } from './features/zakat/ZakatEstimator';
import { StandardCalculator } from './features/calculator/StandardCalculator';
import { StockPurification } from './features/purification/StockPurification';
import { SubscribeModal } from './features/premium/SubscribeModal';
import { Calculator, Coins, ShieldAlert, LogIn, LogOut, Crown, Clock } from 'lucide-react';
const MainApp: React.FC = () => {
const { user, signInWithGoogle, signOut } = useAuth();
const { isSubscribed, isTrialActive, trialDaysLeft } = useSubscription();
const [activeTab, setActiveTab] = useState<'zakat' | 'calc' | 'stocks'>('zakat');
const [isUpgradeOpen, setIsUpgradeOpen] = useState(false);
return (

Z

Zakati Pro

Ethical & Halal Financial Suite

{isTrialActive && (

 {trialDaysLeft}d Trial Left

)}
<button onClick={() => setIsUpgradeOpen(true)} className="inline-flex items-center gap-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 px-3.5 py-2 text-xs font-semibold text-white">
 {isSubscribed && !isTrialActive ? 'Pro Active' : 'Upgrade'}

{user ? (
<button onClick={signOut} className="inline-flex items-center gap-1.5 rounded-xl bg-slate-800 px-3 py-2 text-xs font-medium text-slate-200">
 Sign Out

) : (
<button onClick={signInWithGoogle} className="inline-flex items-center gap-1.5 rounded-xl bg-white text-slate-900 px-3.5 py-2 text-xs font-semibold">
 Sign in with Google

)}

<button onClick={() => setActiveTab('zakat')} className={flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold${activeTab === 'zakat' ? 'bg-emerald-600 text-white' : 'bg-slate-900 text-slate-400 border border-slate-800'}}> <Coins className="w-4 h-4" /> Zakat Estimator </button> <button onClick={() => setActiveTab('calc')} className={flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold latex
{activeTab === 'calc' ? 'bg-emerald-600 text-white' : 'bg-slate-900 text-slate-400 border border-slate-800'}`}> <Calculator className="w-4 h-4" /> Calculator </button> <button onClick={() => setActiveTab('stocks')} className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold 

{activeTab === 'stocks' ? 'bg-emerald-600 text-white' : 'bg-slate-900 text-slate-400 border border-slate-800'}`}>
 Stock Purification

{activeTab === 'zakat' && <ZakatEstimator onOpenUpgrade={() => setIsUpgradeOpen(true)} />}
{activeTab === 'calc' && }
{activeTab === 'stocks' && <StockPurification onOpenUpgrade={() => setIsUpgradeOpen(true)} />}

<SubscribeModal isOpen={isUpgradeOpen} onClose={() => setIsUpgradeOpen(false)} />

);
};
export default function App() {
return (

);
}
EOF
Zip everything automatically
zip -r Zakati-Pro-App.zip "APP_DIR to GitHub."