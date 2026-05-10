export default function Users() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white">Пользователи</h1>
          <p className="text-gray-400 mt-2">Управление пользователями VPN</p>
        </div>
        <button className="btn btn-primary">
          Добавить пользователя
        </button>
      </div>

      <div className="card">
        <p className="text-gray-400">Список пользователей будет здесь...</p>
      </div>
    </div>
  )
}
