using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace IaC.aks101.GuineaPig.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ConfigMapTestController : ControllerBase
    {
        private readonly ILogger<ConfigMapTestController> _logger;

        public ConfigMapTestController(ILogger<ConfigMapTestController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public IActionResult Get()
        {
            _logger.LogDebug("Debug log");
            _logger.LogInformation("Information log");
            _logger.LogWarning("Warning log");
            _logger.LogError("Error log");
            _logger.LogCritical("Critical log");
            return Ok("[configmaptest] - OK");
        }
    }
}
