import React, { useState, useEffect, useMemo } from 'react';
import { 
  LayoutDashboard, 
  Receipt, 
  Bot, 
  PlusCircle, 
  Bell, 
  ShoppingCart, 
  CreditCard, 
  Utensils, 
  Home, 
  Film, 
  Plane,
  ArrowUpRight,
  ArrowDownLeft,
  ChevronRight,
  AlertTriangle,
  Send,
  User
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

// --- Types ---

type TransactionType = 'income' | 'expense';

interface Transaction {
  id: string;
  title: string;
  amount: number;
  type: TransactionType;
  category: string;
  date: string;
}

interface Bill {
  id: string;
  title: string;
  amount: number;
  dueDate: string;
  category: string;
  isRecurring: boolean;
}

interface Budget {
  category: string;
  limit: number;
  spent: number;
}

// --- Mock Data ---

const INITIAL_TRANSACTIONS: Transaction[] = [
  { id: '1', title: 'Apple Store', amount: 129.00, type: 'expense', category: 'Elektronik', date: 'Hari ini, 14:45' },
  { id: '2', title: 'Pembayaran Klien', amount: 4200.00, type: 'income', category: 'Pendapatan', date: 'Kemarin' },
  { id: '3', title: 'The Green Bistro', amount: 54.20, type: 'expense', category: 'Makan di Luar', date: 'Kemarin' },
];

const INITIAL_BILLS: Bill[] = [
  { id: '1', title: 'Paket Internet/TV', amount: 145.00, dueDate: '2023-10-26', category: 'Utilitas', isRecurring: true },
  { id: '2', title: 'Listrik', amount: 82.40, dueDate: '2023-09-24', category: 'Utilitas', isRecurring: true },
  { id: '3', title: 'Pinjaman Mobil', amount: 450.00, dueDate: '2023-10-01', category: 'Keuangan', isRecurring: true },
];

const INITIAL_BUDGETS: Budget[] = [
  { category: 'PERUMAHAN', limit: 2500, spent: 2200 },
  { category: 'GAYA HIDUP', limit: 1000, spent: 1450 },
  { category: 'TABUNGAN', limit: 5000, spent: 4000 },
];

// --- Components ---

const BottomNav = ({ activeTab, setActiveTab }: { activeTab: string, setActiveTab: (tab: string) => void }) => {
  const tabs = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'bills', label: 'Tagihan', icon: Receipt },
    { id: 'ai', label: 'Asisten AI', icon: Bot },
    { id: 'transactions', label: 'Baru', icon: PlusCircle },
  ];

  return (
    <nav className="fixed bottom-0 left-0 w-full flex justify-around items-center px-4 pt-3 pb-8 bg-white/90 backdrop-blur-xl rounded-t-[2rem] z-50 shadow-[0_-8px_24px_rgba(0,0,0,0.05)] border-t border-border-color">
      {tabs.map((tab) => {
        const Icon = tab.icon;
        const isActive = activeTab === tab.id;
        return (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex flex-col items-center justify-center px-5 py-2 rounded-xl transition-all duration-300 ease-out active:scale-90 ${
              isActive 
                ? 'bg-cta-aqua text-text-dark-blue' 
                : 'text-text-muted hover:text-text-dark-blue'
            }`}
          >
            <Icon size={20} strokeWidth={isActive ? 2.5 : 2} />
            <span className="text-[10px] font-extrabold uppercase tracking-wider mt-1">{tab.label}</span>
          </button>
        );
      })}
    </nav>
  );
};

const Dashboard = ({ transactions, budgets }: { transactions: Transaction[], budgets: Budget[] }) => {
  const totalIncome = 18200;
  const totalExpenses = 5750;
  const remaining = totalIncome - totalExpenses;

  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="space-y-6 pb-32"
    >
      {/* Summary Row */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-text-dark-blue text-white p-5 rounded-xl border-none flex flex-col gap-2">
          <span className="text-[12px] font-semibold uppercase text-white/70">Saldo Utama</span>
          <span className="text-3xl font-bold">Rp {remaining.toLocaleString()}</span>
        </div>
        <div className="bg-white p-5 rounded-xl border border-border-color flex flex-col gap-2">
          <span className="text-[12px] font-semibold uppercase text-text-muted">Pendapatan Bulanan</span>
          <span className="text-3xl font-bold text-text-dark-blue">Rp {totalIncome.toLocaleString()}</span>
        </div>
        <div className="bg-white p-5 rounded-xl border border-border-color flex flex-col gap-2">
          <span className="text-[12px] font-semibold uppercase text-text-muted">Pengeluaran Bulanan</span>
          <span className="text-3xl font-bold text-text-dark-blue">Rp {totalExpenses.toLocaleString()}</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column */}
        <div className="lg:col-span-2 space-y-6">
          {/* Budget Widget */}
          <div className="bg-white p-6 rounded-2xl border border-border-color">
            <div className="text-base font-bold flex items-center gap-2">
              Pelacak Anggaran: Makanan & Belanja
            </div>
            <div className="mt-4">
              <div className="w-full h-3 bg-[#ECEFF1] rounded-full overflow-hidden relative">
                <div className="h-full bg-cta-aqua rounded-full" style={{ width: '82%' }}></div>
              </div>
              <div className="flex justify-between mt-2 text-sm font-semibold">
                <span>Rp 2.460.000 / Rp 3.000.000</span>
                <span>82%</span>
              </div>
            </div>
          </div>

          {/* AI Engine Pane */}
          <div className="bg-card-pale-blue rounded-2xl p-6 border border-[#BBDEFB] flex flex-col gap-4">
            <div className="text-base font-bold flex items-center gap-2">
              Analisis AI Lokal <span className="bg-cta-aqua text-text-dark-blue text-[10px] px-2 py-1 rounded font-extrabold uppercase">Mesin Offline</span>
            </div>
            <div className="bg-white rounded-xl p-4 border-l-4 border-cta-aqua polish-shadow">
              <div className="text-[11px] font-extrabold text-cta-aqua uppercase mb-1">Aturan A: Rasio 50/30/20</div>
              <div className="text-sm font-medium leading-relaxed">
                Peringatan: Pengeluaran 'Wants' Anda mencapai 32%. Anda telah melebihi batas 30% untuk bulan ini. Disarankan kurangi belanja non-esensial.
              </div>
            </div>
            <div className="bg-white rounded-xl p-4 border-l-4 border-text-dark-blue polish-shadow">
              <div className="text-[11px] font-extrabold text-text-dark-blue uppercase mb-1">Aturan B: Dana Darurat</div>
              <div className="text-sm font-medium leading-relaxed">
                Saldo Tabungan saat ini setara 4.1x pengeluaran bulanan. Status: Aman (Di atas target minimum 3x).
              </div>
            </div>
          </div>

          {/* Recent Activity */}
          <section className="space-y-4">
            <div className="flex justify-between items-center">
              <h3 className="text-base font-bold text-text-dark-blue">Aktivitas Terbaru</h3>
              <button className="text-text-muted font-bold text-sm hover:underline">Lihat Semua</button>
            </div>
            <div className="bg-white rounded-2xl border border-border-color overflow-hidden">
              {transactions.map((tx, idx) => (
                <div key={tx.id} className={`p-4 flex items-center gap-4 hover:bg-background transition-colors cursor-pointer group ${idx !== transactions.length - 1 ? 'border-bottom border-[#F1F1F1]' : ''}`}>
                  <div className="w-10 h-10 bg-card-pale-blue rounded-full flex items-center justify-center text-text-dark-blue">
                    {tx.category === 'Elektronik' && <ShoppingCart size={18} />}
                    {tx.category === 'Pendapatan' && <CreditCard size={18} />}
                    {tx.category === 'Makan di Luar' && <Utensils size={18} />}
                  </div>
                  <div className="flex-1">
                    <p className="font-bold text-sm text-text-dark-blue">{tx.title}</p>
                    <p className="text-xs text-text-muted">{tx.category} • {tx.date}</p>
                  </div>
                  <p className={`font-bold text-sm ${tx.type === 'income' ? 'text-cta-aqua' : 'text-text-dark-blue'}`}>
                    {tx.type === 'income' ? '+' : '-'}Rp {tx.amount.toLocaleString()}
                  </p>
                </div>
              ))}
            </div>
          </section>
        </div>

        {/* Right Column */}
        <div className="space-y-6">
          <div className="bg-white rounded-2xl border border-border-color p-5 flex flex-col gap-4">
            <div className="text-base font-bold">Tagihan Mendatang</div>
            <div className="space-y-1">
              <div className="flex justify-between items-center py-3 border-b border-[#F1F1F1]">
                <div className="bill-info">
                  <h4 className="text-sm font-bold mb-0.5">Internet & WiFi</h4>
                  <p className="text-xs text-text-muted">Jatuh tempo dalam 3 hari • Berulang</p>
                </div>
                <div className="text-right">
                  <div className="text-sm font-bold text-text-dark-blue">Rp 450.000</div>
                  <span className="text-[10px] font-bold text-[#D32F2F] bg-[#FFEBEE] px-1.5 py-0.5 rounded">PENGINGAT AKTIF</span>
                </div>
              </div>
              <div className="flex justify-between items-center py-3 border-b border-[#F1F1F1]">
                <div className="bill-info">
                  <h4 className="text-sm font-bold mb-0.5">Token Listrik</h4>
                  <p className="text-xs text-text-muted">Jatuh tempo dalam 5 hari</p>
                </div>
                <div className="text-sm font-bold text-text-dark-blue">Rp 200.000</div>
              </div>
              <div className="flex justify-between items-center py-3">
                <div className="bill-info">
                  <h4 className="text-sm font-bold mb-0.5">Netflix Premium</h4>
                  <p className="text-xs text-text-muted">Jatuh tempo dalam 12 hari • Berulang</p>
                </div>
                <div className="text-sm font-bold text-text-dark-blue">Rp 186.000</div>
              </div>
            </div>
            <button className="w-full mt-4 py-3 bg-cta-aqua border-none rounded-lg font-extrabold text-text-dark-blue text-xs cursor-pointer active:scale-95 transition-transform">
              + TAMBAH TRANSAKSI BARU
            </button>
          </div>
        </div>
      </div>
    </motion.div>
  );
};

const BillManager = ({ bills }: { bills: Bill[] }) => {
  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="space-y-8 pb-32"
    >
      <section className="space-y-2">
        <p className="text-text-muted font-bold tracking-wider uppercase text-[12px]">Total Jatuh Tempo bulan ini</p>
        <div className="flex items-baseline gap-2">
          <span className="text-5xl font-extrabold tracking-tight text-text-dark-blue">Rp 1.482.500</span>
        </div>
      </section>

      <section className="relative overflow-hidden rounded-2xl bg-card-pale-blue p-6 border border-[#BBDEFB] shadow-sm">
        <div className="flex items-start gap-4">
          <div className="bg-cta-aqua p-3 rounded-lg flex items-center justify-center">
            <Bell className="text-text-dark-blue" size={24} />
          </div>
          <div className="flex-1 space-y-3">
            <h3 className="text-text-dark-blue font-bold text-lg leading-tight">Izinkan notifikasi untuk mengingatkan tagihan Anda.</h3>
            <p className="text-text-dark-blue/80 text-sm leading-relaxed">Jangan lewatkan pembayaran. Dapatkan pengingat cerdas 2 hari sebelum tagihan jatuh tempo.</p>
            <div className="flex gap-3 pt-1">
              <button className="bg-cta-aqua text-text-dark-blue font-extrabold px-6 py-2.5 rounded-lg text-xs active:scale-95 transition-all">Izinkan</button>
              <button className="text-text-dark-blue font-bold px-4 py-2.5 text-xs">Nanti</button>
            </div>
          </div>
        </div>
      </section>

      <section className="space-y-6">
        <div className="flex justify-between items-center">
          <h2 className="text-xl font-extrabold text-text-dark-blue">Tagihan Mendatang</h2>
          <span className="text-text-muted font-bold text-sm">Lihat Kalender</span>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {bills.map((bill) => (
            <div key={bill.id} className="bg-white p-5 rounded-2xl border border-border-color space-y-4 hover:shadow-md transition-shadow">
              <div className="flex justify-between items-start">
                <div className="bg-card-pale-blue p-3 rounded-full">
                  <Receipt className="text-text-dark-blue" size={20} />
                </div>
                <span className="bg-[#FFEBEE] text-[#D32F2F] font-bold text-[10px] uppercase tracking-widest px-2 py-1 rounded">Jatuh tempo dalam 2 hari</span>
              </div>
              <div>
                <h4 className="text-text-dark-blue font-bold text-lg">{bill.title}</h4>
                <p className="text-text-muted text-sm">{bill.category}</p>
              </div>
              <div className="flex justify-between items-end border-t border-[#F1F1F1] pt-4">
                <div>
                  <p className="text-text-muted text-[10px] uppercase font-bold tracking-tighter">Jumlah</p>
                  <p className="text-xl font-bold text-text-dark-blue">Rp {bill.amount.toLocaleString()}</p>
                </div>
                <button className="bg-cta-aqua text-text-dark-blue w-10 h-10 rounded-lg flex items-center justify-center active:scale-90 transition-transform">
                  <PlusCircle size={20} />
                </button>
              </div>
            </div>
          ))}
        </div>
      </section>
    </motion.div>
  );
};

const AIAssistant = () => {
  const [messages, setMessages] = useState([
    { role: 'ai', content: "Berdasarkan pengeluaran Anda di **Café Lumière**, Anda telah mencapai batas \"Makan di Luar\" untuk minggu ini. Haruskah kita menyesuaikan anggaran Anda untuk akhir pekan?" },
    { role: 'user', content: "Bisakah Anda menunjukkan ringkasan pengeluaran belanja saya dibandingkan bulan lalu?" },
  ]);
  const [input, setInput] = useState('');

  const handleSend = () => {
    if (!input.trim()) return;
    setMessages([...messages, { role: 'user', content: input }]);
    setInput('');
    // Simulate AI response
    setTimeout(() => {
      setMessages(prev => [...prev, { role: 'ai', content: "Saya telah menganalisis data Anda. Pengeluaran belanja Anda **6,6% lebih rendah** dari bulan lalu. Kerja bagus!" }]);
    }, 1000);
  };

  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="flex flex-col h-[calc(100vh-180px)] pb-32"
    >
      <div className="mb-8">
        <h2 className="text-3xl font-extrabold tracking-tight text-text-dark-blue mb-2">Halo, Alex</h2>
        <p className="text-text-muted max-w-md leading-relaxed">
          Saya telah menganalisis arus kas Anda untuk bulan Oktober. Anda melacak <span className="text-cta-aqua font-bold">12% lebih baik</span> dari bulan lalu.
        </p>
      </div>

      <div className="flex-grow flex flex-col bg-white rounded-2xl overflow-hidden border border-border-color polish-shadow">
        <div className="flex-grow overflow-y-auto space-y-6 p-6 no-scrollbar">
          {messages.map((msg, i) => (
            <div key={i} className={`flex gap-4 items-end ${msg.role === 'user' ? 'justify-end ml-auto max-w-[85%]' : 'max-w-[85%]'}`}>
              {msg.role === 'ai' && (
                <div className="w-8 h-8 rounded-full bg-cta-aqua flex items-center justify-center flex-shrink-0">
                  <Bot className="text-text-dark-blue" size={16} />
                </div>
              )}
              <div className={`p-4 polish-shadow ${
                msg.role === 'ai' 
                  ? 'bg-card-pale-blue rounded-t-xl rounded-br-xl text-text-dark-blue border border-[#BBDEFB]' 
                  : 'bg-white rounded-t-xl rounded-bl-xl text-text-dark-blue border border-border-color'
              }`}>
                <p className="text-sm leading-relaxed">{msg.content}</p>
              </div>
              {msg.role === 'user' && (
                <div className="w-8 h-8 rounded-full bg-background flex items-center justify-center flex-shrink-0 border border-border-color">
                  <User className="text-text-muted" size={16} />
                </div>
              )}
            </div>
          ))}
        </div>

        <div className="p-4 bg-background border-t border-border-color">
          <div className="flex items-center gap-3 bg-white rounded-xl px-4 py-2 border border-border-color focus-within:border-cta-aqua transition-colors duration-300">
            <input 
              className="bg-transparent border-none focus:ring-0 flex-grow text-text-dark-blue placeholder:text-text-muted/50 font-medium py-2 outline-none" 
              placeholder="Tanya tentang arus kas Anda..." 
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSend()}
            />
            <button 
              onClick={handleSend}
              className="w-10 h-10 rounded-lg bg-cta-aqua text-text-dark-blue flex items-center justify-center active:scale-90 transition-transform shadow-sm"
            >
              <Send size={18} />
            </button>
          </div>
        </div>
      </div>
    </motion.div>
  );
};

const AddTransaction = ({ onAdd }: { onAdd: (tx: Transaction) => void }) => {
  const [type, setType] = useState<TransactionType>('expense');
  const [amount, setAmount] = useState('');
  const [category, setCategory] = useState('Belanja');

  const categories = [
    { id: 'Belanja', icon: ShoppingCart },
    { id: 'Sewa', icon: Home },
    { id: 'Hiburan', icon: Film },
    { id: 'Perjalanan', icon: Plane },
  ];

  const handlePost = () => {
    if (!amount) return;
    onAdd({
      id: Math.random().toString(),
      title: category,
      amount: parseFloat(amount),
      type,
      category,
      date: 'Baru saja'
    });
    setAmount('');
  };

  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="space-y-8 pb-32"
    >
      <div className="mb-8">
        <h2 className="text-[1.5rem] font-extrabold tracking-tight text-text-dark-blue mb-2">Tambah Transaksi</h2>
        <p className="text-text-muted leading-relaxed">Perbarui buku besar fina Anda dengan data arus kas baru.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        <div className="lg:col-span-7 bg-white rounded-2xl p-8 border border-border-color polish-shadow">
          <div className="space-y-10">
            <div className="flex p-1.5 bg-background rounded-xl gap-2 border border-border-color">
              <button 
                onClick={() => setType('expense')}
                className={`flex-1 py-3 px-6 rounded-lg font-extrabold text-xs transition-all duration-300 ${type === 'expense' ? 'bg-text-dark-blue text-white shadow-sm' : 'text-text-muted hover:bg-card-pale-blue'}`}
              >
                PENGELUARAN
              </button>
              <button 
                onClick={() => setType('income')}
                className={`flex-1 py-3 px-6 rounded-lg font-extrabold text-xs transition-all duration-300 ${type === 'income' ? 'bg-text-dark-blue text-white shadow-sm' : 'text-text-muted hover:bg-card-pale-blue'}`}
              >
                PENDAPATAN
              </button>
            </div>

            <div className="space-y-2">
              <label className="text-[12px] font-bold text-text-muted uppercase tracking-widest ml-1">Jumlah</label>
              <div className="flex items-center gap-4 bg-background rounded-xl px-6 py-4 border border-border-color focus-within:border-cta-aqua transition-colors">
                <span className="text-3xl font-extrabold text-text-dark-blue tracking-tight">Rp</span>
                <input 
                  className="w-full bg-transparent border-none focus:ring-0 text-[3.5rem] font-extrabold tracking-tighter text-text-dark-blue placeholder-text-muted/30 leading-none p-0 outline-none" 
                  placeholder="0" 
                  type="number"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                />
              </div>
            </div>

            <div className="space-y-4">
              <label className="text-[12px] font-bold text-text-muted uppercase tracking-widest ml-1">Kategori</label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {categories.map((cat) => {
                  const Icon = cat.icon;
                  const isSelected = category === cat.id;
                  return (
                    <button 
                      key={cat.id}
                      onClick={() => setCategory(cat.id)}
                      className={`flex flex-col items-center justify-center gap-2 p-4 rounded-xl border-2 transition-all ${isSelected ? 'border-cta-aqua bg-card-pale-blue text-text-dark-blue' : 'border-transparent bg-background text-text-muted hover:border-border-color'}`}
                    >
                      <Icon size={24} />
                      <span className="text-[10px] font-extrabold uppercase tracking-wider">{cat.id}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            <button 
              onClick={handlePost}
              className="w-full py-5 rounded-xl bg-cta-aqua text-text-dark-blue font-extrabold text-sm flex items-center justify-center gap-3 shadow-md hover:scale-[1.02] active:scale-[0.98] transition-all duration-300"
            >
              <PlusCircle size={20} />
              KIRIM TRANSAKSI
            </button>
          </div>
        </div>

        <div className="lg:col-span-5 flex flex-col gap-8">
          <div className="relative overflow-hidden rounded-2xl bg-text-dark-blue p-8 aspect-[4/3] flex flex-col justify-between text-white shadow-xl">
            <div className="relative z-10">
              <div className="flex justify-between items-start">
                <span className="text-[10px] uppercase font-extrabold tracking-[0.2em] opacity-60 text-white/70">Kartu fina</span>
                <CreditCard className="text-cta-aqua opacity-80" size={24} />
              </div>
            </div>
            <div className="relative z-10 space-y-1">
              <span className="text-[10px] uppercase font-extrabold tracking-[0.2em] opacity-60 text-white/70">Pratinjau Saldo Baru</span>
              <div className="text-4xl font-extrabold tracking-tighter">
                Rp {(14250000 - (parseFloat(amount) || 0)).toLocaleString()}
              </div>
            </div>
            <div className="absolute -top-10 -right-10 w-48 h-48 bg-cta-aqua/10 rounded-full blur-3xl"></div>
            <div className="absolute -bottom-20 -left-20 w-64 h-64 bg-cta-aqua/5 rounded-full blur-[80px]"></div>
          </div>

          <div className="bg-card-pale-blue p-8 rounded-2xl space-y-4 border border-[#BBDEFB]">
            <h3 className="font-extrabold text-text-dark-blue text-xl tracking-tight">Wawasan Cerdas</h3>
            <p className="text-text-dark-blue/80 text-sm leading-relaxed font-medium">
              Entri "{category}" ini akan menempatkan Anda pada 85% anggaran bulanan Anda. Sisa tunjangan "Hiburan" Anda adalah Rp 200.000.
            </p>
            <div className="pt-4 h-3 w-full bg-white rounded-full overflow-hidden border border-border-color">
              <div className="h-full bg-cta-aqua w-[85%] rounded-full"></div>
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  );
};

// --- Main App ---

export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [transactions, setTransactions] = useState(INITIAL_TRANSACTIONS);
  const [budgets, setBudgets] = useState(INITIAL_BUDGETS);

  const handleAddTransaction = (newTx: Transaction) => {
    setTransactions([newTx, ...transactions]);
    if (newTx.type === 'expense') {
      setBudgets(prev => prev.map(b => 
        b.category === newTx.category.toUpperCase() 
          ? { ...b, spent: b.spent + newTx.amount } 
          : b
      ));
    }
    setActiveTab('dashboard');
  };

  return (
    <div className="min-h-screen bg-background">
      <header className="h-[70px] bg-white border-b border-border-color flex items-center justify-between px-8 sticky top-0 z-50">
        <div className="logo text-2xl font-black text-text-dark-blue tracking-tighter">fina</div>
        <div className="profile flex items-center gap-3">
          <div className="bg-cta-aqua text-text-dark-blue text-[10px] px-2 py-1 rounded font-extrabold uppercase">PREMIUM OFFLINE</div>
          <div className="w-8 h-8 rounded-full bg-card-pale-blue border border-border-color overflow-hidden">
            <img 
              src="https://picsum.photos/seed/user/100/100" 
              alt="User" 
              className="w-full h-full object-cover"
              referrerPolicy="no-referrer"
            />
          </div>
        </div>
      </header>

      <main className="max-w-screen-xl mx-auto px-8 py-6">
        <AnimatePresence mode="wait">
          {activeTab === 'dashboard' && <Dashboard transactions={transactions} budgets={budgets} />}
          {activeTab === 'bills' && <BillManager bills={INITIAL_BILLS} />}
          {activeTab === 'ai' && <AIAssistant />}
          {activeTab === 'transactions' && <AddTransaction onAdd={handleAddTransaction} />}
        </AnimatePresence>
      </main>

      <BottomNav activeTab={activeTab} setActiveTab={setActiveTab} />
    </div>
  );
}
