export default function Configs() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white">Конфигурации</h1>
          <p className="text-gray-400 mt-2">Управление конфигурациями протоколов</p>
        </div>
        <button className="btn btn-primary">
          Создать конфигурацию
        </button>
      </div>

      <div className="card">
        <p className="text-gray-400">Список конфигураций будет здесь...</p>
      </div>
    </div>
  )
}
