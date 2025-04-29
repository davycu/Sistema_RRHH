using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Sistema_RRHH.Clases
{
    public class Departamentos
    {

        public int IdDepartamento { get; set; }
        public string CodigoDepartamento { get; set; }
        public string Nombre { get; set; }
        public int IdSupervisorDepartamento { get; set; }
        public string SupervisorNombre { get; set; }

    }

}