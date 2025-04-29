using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Sistema_RRHH.Clases
{
	public class PeriodoEvaluacion
	{

        public int id_periodo { get; set; }
        public int anio { get; set; }
        public int trimestre { get; set; }
        public DateTime fecha_inicio { get; set; }
        public DateTime fecha_fin { get; set; }

    }
}