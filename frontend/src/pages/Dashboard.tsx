import { useEffect, useState } from 'react'
import { Users as UsersIcon, Activity, HardDrive, TrendingUp } from 'lucide-react'
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
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-white">Панель управления</h1>
        <p className="text-gray-400 mt-2">Обзор системы VPN Shield</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-400 text-sm">Всего пользователей</p>
              <p className="text-3xl font-bold text-white mt-2">
                {stats?.total_users || 0}
              </p>
            </div>
            <div className="w-12 h-12 bg-blue-600/20 rounded-lg flex items-center justify-center">
              <UsersIcon className="w-6 h-6 text-blue-500" />
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-400 text-sm">Активных пользователей</p>
              <p className="text-3xl font-bold text-white mt-2">
                {stats?.active_users || 0}
              </p>
            </div>
            <div className="w-12 h-12 bg-green-600/20 rounded-lg flex items-center justify-center">
              <Activity className="w-6 h-6 text-green-500" />
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-400 text-sm">Активных подключений</p>
              <p className="text-3xl font-bold text-white mt-2">
                {stats?.active_connections || 0}
              </p>
            </div>
            <div className="w-12 h-12 bg-purple-600/20 rounded-lg flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-purple-500" />
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-400 text-sm">Общий трафик</p>
              <p className="text-3xl font-bold text-white mt-2">
                {formatBytes(stats?.total_traffic || 0)}
              </p>
            </div>
            <div className="w-12 h-12 bg-orange-600/20 rounded-lg flex items-center justify-center">
              <HardDrive className="w-6 h-6 text-orange-500" />
            </div>
          </div>
        </div>
      </div>

      {/* Traffic Stats */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card">
          <h3 className="text-xl font-bold text-white mb-4">Загрузка</h3>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between text-sm mb-2">
                <span className="text-gray-400">Upload</span>
                <span className="text-white font-medium">
                  {formatBytes(stats?.total_upload || 0)}
                </span>
              </div>
              <div className="w-full bg-slate-700 rounded-full h-2">
                <div 
                  className="bg-green-500 h-2 rounded-full" 
                  style={{ 
                    width: `${((stats?.total_upload || 0) / (stats?.total_traffic || 1)) * 100}%` 
                  }}
                ></div>
              </div>
            </div>
            <div>
              <div className="flex justify-between text-sm mb-2">
                <span className="text-gray-400">Download</span>
                <span className="text-white font-medium">
                  {formatBytes(stats?.total_download || 0)}
                </span>
              </div>
              <div className="w-full bg-slate-700 rounded-full h-2">
                <div 
                  className="bg-blue-500 h-2 rounded-full" 
                  style={{ 
                    width: `${((stats?.total_download || 0) / (stats?.total_traffic || 1)) * 100}%` 
                  }}
                ></div>
              </div>
            </div>
          </div>
        </div>

        <div className="card">
          <h3 className="text-xl font-bold text-white mb-4">Протоколы</h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3 bg-slate-700/50 rounded-lg">
              <span className="text-gray-300">REALITY</span>
              <span className="px-3 py-1 bg-green-600 text-white text-sm rounded-full">
                Активен
              </span>
            </div>
            <div className="flex items-center justify-between p-3 bg-slate-700/50 rounded-lg">
              <span className="text-gray-300">Hysteria2</span>
              <span className="px-3 py-1 bg-green-600 text-white text-sm rounded-full">
                Активен
              </span>
            </div>
            <div className="flex items-center justify-between p-3 bg-slate-700/50 rounded-lg">
              <span className="text-gray-300">Trojan</span>
              <span className="px-3 py-1 bg-green-600 text-white text-sm rounded-full">
                Активен
              </span>
            </div>
            <div className="flex items-center justify-between p-3 bg-slate-700/50 rounded-lg">
              <span className="text-gray-300">VMess</span>
              <span className="px-3 py-1 bg-green-600 text-white text-sm rounded-full">
                Активен
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* System Info */}
      <div className="card">
        <h3 className="text-xl font-bold text-white mb-4">Информация о системе</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <p className="text-gray-400 text-sm mb-2">Версия</p>
            <p className="text-white font-medium">VPN Shield v1.0.0</p>
          </div>
          <div>
            <p className="text-gray-400 text-sm mb-2">Xray-core</p>
            <p className="text-white font-medium">v1.8.0</p>
          </div>
          <div>
            <p className="text-gray-400 text-sm mb-2">Hysteria2</p>
            <p className="text-white font-medium">v2.0.0</p>
          </div>
        </div>
      </div>
    </div>
  )
}
