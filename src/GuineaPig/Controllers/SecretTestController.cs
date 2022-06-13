using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace IaC.aks101.GuineaPig.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class SecretTestController : ControllerBase
    {
        private readonly ILogger<SecretTestController> _logger;
        private readonly IConfiguration _configuration;

        public SecretTestController(ILogger<SecretTestController> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
        }

        [HttpGet]
        public IActionResult Get()
        {
            _logger.LogInformation($"[guinea-pig] - Database:ConnectionString: {_configuration["Database:ConnectionString"]}");
            return Ok("[secrettest] - OK");
        }
    }
}
