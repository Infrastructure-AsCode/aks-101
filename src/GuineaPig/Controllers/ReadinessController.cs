using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace IaC.aks101.GuineaPig.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ReadinessController : ControllerBase
    {
        private readonly ILogger<ReadinessController> _logger;
        
        public ReadinessController(ILogger<ReadinessController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public IActionResult Ready()
        {
            _logger.LogInformation("[lab-07] - always ready");
            return Ok("[readiness] - always ready");
        }

        [HttpGet("unstable")]
        // readiness/unstable
        public IActionResult Unstable()
        {
            // This endpoint will change the return status from 200 to 500 every minute
            var minutesFromStart = Timekeeper.GetMinutesFromStart();
            if (minutesFromStart % 2 != 0)
            {
                _logger.LogInformation($"{minutesFromStart} min from the start -> response with 200");
                return Ok("[lab-07] - ready");
            }
            else
            {
                _logger.LogInformation($"{minutesFromStart} min from the start -> response with 500");
                return StatusCode(500);
            }
        }
    }
}
