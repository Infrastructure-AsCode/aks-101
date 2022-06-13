using System;
using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace IaC.aks101.GuineaPig.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ApiController : ControllerBase
    {
        private readonly ILogger<ApiController> _logger;

        public ApiController(ILogger<ApiController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public IActionResult Get()
        {
            var message = "[api] - OK.";
            _logger.LogInformation(message);
            return Ok(message);
        }

        [HttpGet("highcpu")]
        public IActionResult HighCpu()
        {
            var sw = Stopwatch.StartNew();
            var x = 0.0001;

            for (var i = 0; i < 2000000; i++)
            {
                x += Math.Sqrt(x);
            }
            sw.Stop();
            var message = $"[api.highcpu] - execution took {sw.ElapsedMilliseconds} ms.";
            _logger.LogInformation(message);
            return Ok(message);
        }
    }
}
