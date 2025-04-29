using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Sistema_RRHH.Clases
{
	public class Notificacion
	{
        public int Id { get; set; }
        public string Mensaje { get; set; }
        public DateTime FechaCreacion { get; set; }
        public bool Leido { get; set; }
        public string Tipo { get; set; }
    }
}