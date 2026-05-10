import { useEffect, useState } from 'react'
import { Users as UsersIcon, Activity, HardDrive, TrendingUp, Zap, Shield, Globe } from 'lucide-react'
import api from '../api/client'

interface DashboardStats {
  total_users: number
  active_users: number
  active_connections: number
  total_upload: number
  total_download: number
  total_traffic: number
}

export default function Dashboard() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchStats()
  }, [])

  const fetchStats = async () => {
    try {
      const response = await api.get('/stats/dashboard')
      setStats(response.data)
    } catch (error) {
      console.error('Failed to fetch stats', error)
    } finally {
      setLoading(false)
    }
  }

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="relative">
          <div className="w-16 h-16 border-4 border-blue-500/30 border-t-blue-500 rounded-full animate-spin"></div>
          <Shield className="w-8 h-8 text-blue-500 absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 animate-pulse" />
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-4xl font-bold bg-gradient-to-r from-blue-400 via-cyan-400 to-blue-400 bg-clip-text text-transparent">
            Панель управления
          </h1>
          <p className="text-gray-400 mt-2 flex items-center gap-2">
            <Globe className="w-4 h-4" />
            Обзор системы VPN Shield
          </p>
        </div>
        <div className="flex items-center gap-2 px-4 py-2 bg-green-500/20 border border-green-500/30 rounded-xl">
          <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
          <span className="text-green-400 text-sm font-semibold">Система работает</span>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="stat-card group">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-400 text-sm font-medium mb-1">Всего пользователей</p>
              <p className="text-4xl font-bold text-white mt-2 group-hover:scale-110 transition-transform">
                {stats?.total_users || 0}
              </p>
              <p className="text-xs text-blue-400 mt-2">↑ Зарегистрировано</p>
            </div>
            <div className="relative">
              <div className="absolute inset-0 bg-blue-500 rounded-2xl blur-xl opacity-50 group-hover:opacity-75 transition-opacity"></div>
              <div className="relative w-16 h-16 bg-gradient-to-br from-blue-600 to-blue-700 rounded-2xl flex items-center justify-center shadow-lg">
                <UsersIcon className="w-8 h-8 text-white" />
              </div>
            </div>
          </div>
        </div>

        <div className="stat-card group">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-400 text-sm font-medium mb-1">Активных пользователей</p>
              <p className="text-4xl font-bold text-white mt-2 group-hover:scale-110 transition-transform">
                {stats?.active_users || 0}
              </p>
              <p className="text-xs text-green-400 mt-2">↑ Онлайн сейчас</p>
            </div>
            <div className="relative">
              <div className="absolute inset-0 bg-green-500 rounded-2xl blur-xl opacity-50 group-hover:opacity-75 transition-opacity"></div>
              <div className="relative w-16 h-16 bg-gradient-to-br from-green-600 to-emerald-700 rounded-2xl flex items-center justify-center shadow-lg">
                <Activity className="w-8 h-8 text-white" />
              </div>
            </div>
          </div>
        </div>

        <div className="stat-card group">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-400 text-sm font-medium mb-1">Активных подключений</p>
              <p className="text-4xl font-bold text-white mt-2 group-hover:scale-110 transition-transform">
                {stats?.active_connections || 0}
              </p>
              <p className="text-xs text-purple-400 mt-2">↑ Соединений</p>
            </div>
            <div className="relative">
              <div className="absolute inset-0 bg-purple-500 rounded-2xl blur-xl opacity-50 group-hover:opacity-75 transition-opacity"></div>
              <div className="relative w-16 h-16 bg-gradient-to-br from-purple-600 to-pink-700 rounded-2xl flex items-center justify-center shadow-lg">
                <TrendingUp className="w-8 h-8 text-white" />
              </div>
            </div>
          </div>
        </div>

        <div className="stat-card group">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-400 text-sm font-medium mb-1">Общий трафик</p>
              <p className="text-4xl font-bold text-white mt-2 group-hover:scale-110 transition-transform">
                {formatBytes(stats?.total_traffic || 0)}
              </p>
              <p className="text-xs text-orange-400 mt-2">↑ Передано данных</p>
            </div>
            <div className="relative">
              <div className="absolute inset-0 bg-orange-500 rounded-2xl blur-xl opacity-50 group-hover:opacity-75 transition-opacity"></div>
              <div className="relative w-16 h-16 bg-gradient-to-br from-orange-600 to-red-700 rounded-2xl flex items-center justify-center shadow-lg">
                <HardDrive className="w-8 h-8 text-white" />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Traffic Stats */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 bg-gradient-to-br from-green-600 to-blue-600 rounded-xl flex items-center justify-center">
              <Zap className="w-6 h-6 text-white" />
            </div>
            <h3 className="text-2xl font-bold text-white">Статистика трафика</h3>
          </div>
          <div className="space-y-6">
            <div>
              <div className="flex justify-between text-sm mb-3">
                <span className="text-gray-400 font-medium">Upload</span>
                <span className="text-white font-bold">
                  {formatBytes(stats?.total_upload || 0)}
                </span>
              </div>
              <div className="w-full bg-slate-700/50 rounded-full h-3 overflow-hidden">
                <div 
                  className="bg-gradient-to-r from-green-500 to-emerald-500 h-3 rounded-full shadow-lg shadow-green-500/50 transition-all duration-500" 
                  style={{ 
                    width: `${((stats?.total_upload || 0) / (stats?.total_traffic || 1)) * 100}%` 
                  }}
                ></div>
              </div>
            </div>
            <div>
              <div className="flex justify-between text-sm mb-3">
                <span className="text-gray-400 font-medium">Download</span>
                <span className="text-white font-bold">
                  {formatBytes(stats?.total_download || 0)}
                </span>
              </div>
              <div className="w-full bg-slate-700/50 rounded-full h-3 overflow-hidden">
                <div 
                  className="bg-gradient-to-r from-blue-500 to-cyan-500 h-3 rounded-full shadow-lg shadow-blue-500/50 transition-all duration-500" 
                  style={{ 
                    width: `${((stats?.total_download || 0) / (stats?.total_traffic || 1)) * 100}%` 
                  }}
                ></div>
              </div>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-10 h-10 bg-gradient-to-br from-purple-600 to-pink-600 rounded-xl flex items-center justify-center">
              <Shield className="w-6 h-6 text-white" />
            </div>
            <h3 className="text-2xl font-bold text-white">VPN Протоколы</h3>
          </div>
          <div className="space-y-3">
            {[
              { name: 'REALITY', color: 'from-blue-600 to-cyan-600', icon: '🛡️' },
              { name: 'Hysteria2', color: 'from-purple-600 to-pink-600', icon: '⚡' },
              { name: 'Trojan', color: 'from-green-600 to-emerald-600', icon: '🔒' },
              { name: 'VMess', color: 'from-orange-600 to-red-600', icon: '🚀' },
            ].map((protocol) => (
              <div key={protocol.name} className="flex items-center justify-between p-4 bg-slate-700/30 hover:bg-slate-700/50 rounded-xl transition-all duration-200 group">
                <div className="flex items-center gap-3">
                  <span className="text-2xl">{protocol.icon}</span>
                  <span className="text-gray-200 font-semibold group-hover:text-white transition-colors">{protocol.name}</span>
                </div>
                <span className={`badge badge-success`}>
                  <span className="w-1.5 h-1.5 bg-green-500 rounded-full animate-pulse mr-2"></span>
                  Активен
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* System Info */}
      <div className="card">
        <h3 className="text-2xl font-bold text-white mb-6 flex items-center gap-3">
          <div className="w-10 h-10 bg-gradient-to-br from-cyan-600 to-blue-600 rounded-xl flex items-center justify-center">
            <Globe className="w-6 h-6 text-white" />
          </div>
          Информация о системе
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="p-4 bg-slate-700/30 rounded-xl hover:bg-slate-700/50 transition-all">
            <p className="text-gray-400 text-sm mb-2 font-medium">Версия системы</p>
            <p className="text-white font-bold text-lg">VPN Shield v1.0.0</p>
            <p className="text-xs text-blue-400 mt-1">Последняя версия</p>
          </div>
          <div className="p-4 bg-slate-700/30 rounded-xl hover:bg-slate-700/50 transition-all">
            <p className="text-gray-400 text-sm mb-2 font-medium">Xray-core</p>
            <p className="text-white font-bold text-lg">v1.8.0</p>
            <p className="text-xs text-green-400 mt-1">Стабильная</p>
          </div>
          <div className="p-4 bg-slate-700/30 rounded-xl hover:bg-slate-700/50 transition-all">
            <p className="text-gray-400 text-sm mb-2 font-medium">Hysteria2</p>
            <p className="text-white font-bold text-lg">v2.0.0</p>
            <p className="text-xs text-purple-400 mt-1">Оптимизирована</p>
          </div>
        </div>
      </div>
    </div>
  )
}
