using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Sistema_RRHH.Clases
{
    public class Contacto
    {

        public int id_usuario { get; set; }
        public string nombre { get; set; }
        public string apellido { get; set; }
        public string cargo { get; set; }
        public string departamento { get; set; }
        public bool tieneMensajesNuevos { get; set; }

    }
}