using Barotrauma.LuaCs;
using Barotrauma.LuaCs.Data;

namespace MedicalIcons
{
    public sealed class Plugin : IAssemblyPlugin
    {
        public IConfigService ConfigService { get; set; }
        public IPluginManagementService PluginService { get; set; }
        public ILoggerService LoggerService { get; set; }

        public void Initialize()
        {
            LoggerService?.LogMessage("[Medical Icons] C# helpers loaded", null, null);
        }

        public void OnLoadCompleted() { }

        public void PreInitPatching() { }

        public void Dispose() { }
    }
}
