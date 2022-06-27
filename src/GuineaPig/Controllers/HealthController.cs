using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace IaC.aks101.GuineaPig.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class HealthController : ControllerBase
    {
        private readonly ILogger<HealthController> _logger;
        
        public HealthController(ILogger<HealthController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public IActionResult Healthy()
        {
            var message = "[lab-07] - always healthy";
            _logger.LogInformation(message);
            return Ok(message);
        }
        
        [HttpGet("almost_healthy")]
        public IActionResult AlmostHealthy()
        {
            // For the first 10 seconds that the app is alive, the /health/almost_healthy handler returns a status of 200. 
            // After that, the handler returns a status of 500.
            var secondsFromStart = Timekeeper.GetSecondsFromStart();
            _logger.LogInformation($"{secondsFromStart} seconds from start...");
            var secondsToWait = 10;
            if (secondsFromStart < secondsToWait)
            {
                _logger.LogInformation($"< {secondsToWait} seconds -> response with 200");
                return Ok("[lab-07] - healthy first 10 sec");
            }

            _logger.LogInformation($"> {secondsToWait} seconds -> response with 500");
            return StatusCode(500);
        }
    }
}
