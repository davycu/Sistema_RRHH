using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Sistema_RRHH.Clases
{
	public class EvaluacionPregunta
	{

        public int id_pregunta { get; set; }
        public int puntaje_empleado { get; set; }
        public string comentario_empleado { get; set; }

    }
}