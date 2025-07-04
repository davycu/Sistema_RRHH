USE [master]
GO
/****** Object:  Database [ProyectoRRHH]    Script Date: 4/23/2025 6:34:55 PM ******/
CREATE DATABASE [ProyectoRRHH]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'ProyectoRRHH', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\ProyectoRRHH.mdf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'ProyectoRRHH_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\ProyectoRRHH_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [ProyectoRRHH] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [ProyectoRRHH].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [ProyectoRRHH] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET ARITHABORT OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [ProyectoRRHH] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [ProyectoRRHH] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [ProyectoRRHH] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET  DISABLE_BROKER 
GO
ALTER DATABASE [ProyectoRRHH] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [ProyectoRRHH] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [ProyectoRRHH] SET  MULTI_USER 
GO
ALTER DATABASE [ProyectoRRHH] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [ProyectoRRHH] SET DB_CHAINING OFF 
GO
ALTER DATABASE [ProyectoRRHH] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [ProyectoRRHH] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [ProyectoRRHH]
GO
/****** Object:  StoredProcedure [dbo].[ActualizarVacacionesMensual]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ActualizarVacacionesMensual]
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE sp
    SET sp.horas_disponibles = 
        CASE 
            WHEN sp.horas_disponibles + ca2.accrualHours > ca2.maxAcumulableHours 
                 THEN ca2.maxAcumulableHours 
            ELSE sp.horas_disponibles + ca2.accrualHours
        END
    FROM SaldoPermisos sp
    INNER JOIN Empleados e ON sp.id_empleado = e.id_empleado
    INNER JOIN TiposPermisos tp ON sp.id_tipo_permiso = tp.id_tipo_permiso
    CROSS APPLY (
        SELECT 
            CASE 
                WHEN DATEDIFF(YEAR, e.fecha_ingreso, GETDATE()) < 1 
                     THEN ROUND(10.0/12.0, 2)    -- Acumulación en días/mes para menos de 1 año (≈0.83)
                WHEN DATEDIFF(YEAR, e.fecha_ingreso, GETDATE()) < 2 
                     THEN 1.00                   -- 1 día/mes para 1 año de servicio
                WHEN DATEDIFF(YEAR, e.fecha_ingreso, GETDATE()) < 3 
                     THEN ROUND(15.0/12.0, 2)    -- ≈1.25 días/mes para 2 años de servicio
                ELSE ROUND(20.0/12.0, 2)        -- ≈1.67 días/mes para 3 años o más
            END AS accrualDays,
            CASE 
                WHEN DATEDIFF(YEAR, e.fecha_ingreso, GETDATE()) < 1 
                     THEN 10.0 * 2               -- Máximo acumulable: 20 días
                WHEN DATEDIFF(YEAR, e.fecha_ingreso, GETDATE()) < 2 
                     THEN 12.0 * 2               -- 24 días
                WHEN DATEDIFF(YEAR, e.fecha_ingreso, GETDATE()) < 3 
                     THEN 15.0 * 2               -- 30 días
                ELSE 20.0 * 2                   -- 40 días
            END AS maxAcumulableDays
    ) ca
    CROSS APPLY (
        SELECT 
            ROUND(ca.accrualDays * 8.0, 2) AS accrualHours,       -- convertir días a horas
            ROUND(ca.maxAcumulableDays * 8.0, 2) AS maxAcumulableHours
    ) ca2
    WHERE tp.nombre_permiso = 'Vacaciones';
END;
GO
/****** Object:  StoredProcedure [dbo].[AutoAprobarPermiso]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AutoAprobarPermiso]
    @id_permiso INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @id_empleado INT,
        @fecha_inicio DATE,
        @horasSolicitadas INT,
        @diasSolicitados INT,
        @puntajeTotal INT,
        @diasAutoAprobadosAcumulados INT,
        @diasDisponibles INT,
        @diasAprobar INT,
        @anioAnterior INT,
        @anioActual INT;

    -- Obtener datos del permiso solicitado
    SELECT 
        @id_empleado = id_empleado,
        @fecha_inicio = fecha_inicio,
        @horasSolicitadas = horas_solicitadas
    FROM Permisos
    WHERE id_permiso = @id_permiso;

    IF @horasSolicitadas < 8
        RETURN;

    SET @diasSolicitados = CEILING(@horasSolicitadas / 8.0);
    SET @anioActual = YEAR(GETDATE());
    SET @anioAnterior = @anioActual - 1;

    SELECT @puntajeTotal = SUM(resultado_promedio)
    FROM Evaluaciones e
    INNER JOIN PeriodosEvaluacion pe ON e.id_periodo = pe.id_periodo
    WHERE e.id_empleado = @id_empleado
      AND pe.anio = @anioAnterior
      AND e.finalizada = 1
      AND e.EvaluadaSupervisor = 1;

    IF @puntajeTotal BETWEEN 170 AND 180
    BEGIN
         SELECT @diasAutoAprobadosAcumulados = ISNULL(SUM(dias_AutoAprobados), 0)
    FROM Permisos
    WHERE id_empleado = @id_empleado
	  AND id_permiso <> @id_permiso
      AND fecha_revisado IS NOT NULL
      AND YEAR(fecha_revisado) = @anioActual
      AND id_tipo_permiso = (SELECT TOP 1 id_tipo_permiso 
                             FROM TiposPermisos 
                             WHERE nombre_permiso = 'Asueto')
      AND estado = 'aprobado';

        SET @diasDisponibles = 3 - @diasAutoAprobadosAcumulados;

        IF @diasDisponibles > 0
        BEGIN
            IF @diasSolicitados > @diasDisponibles
                SET @diasAprobar = @diasDisponibles;
            ELSE
                SET @diasAprobar = @diasSolicitados;

            UPDATE Permisos
    SET estado = 'aprobado',
        dias_AutoAprobados = @diasAprobar,
        comentarios_supervisor = 'Aprobado automáticamente. Días restantes para auto aprobar: ' 
                                 + CAST((3 - (@diasAutoAprobadosAcumulados + @diasAprobar)) AS VARCHAR(10)) + '.',
        fecha_revisado = GETDATE()
            WHERE id_permiso = @id_permiso;
        END
        ELSE
        BEGIN
            UPDATE Permisos
            SET comentarios_supervisor = ''
            WHERE id_permiso = @id_permiso;
        END
    END
    ELSE
    BEGIN
        UPDATE Permisos
        SET comentarios_supervisor = ''
        WHERE id_permiso = @id_permiso;
    END
END;
GO
/****** Object:  StoredProcedure [dbo].[CalcularPromedioAnual]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CalcularPromedioAnual]
    @idEmpleado INT,
    @anio INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sumaTotal INT,
            @porcentajeAnual DECIMAL(5,2);

    SELECT @sumaTotal = SUM(ep.puntaje_supervisor)
    FROM EvaluacionesPreguntas ep
    INNER JOIN Evaluaciones e ON ep.id_evaluacion = e.id_evaluacion
    INNER JOIN PeriodosEvaluacion pe ON e.id_periodo = pe.id_periodo
    WHERE e.id_empleado = @idEmpleado
      AND pe.anio = @anio
      AND e.finalizada = 1;  -- Solo evaluaciones finalizadas

    IF @sumaTotal IS NULL
        SET @sumaTotal = 0;

    SET @porcentajeAnual = (@sumaTotal * 100.0) / 180.0;

    SELECT @sumaTotal AS TotalPuntos, @porcentajeAnual AS PorcentajeAnual;
END
GO
/****** Object:  Table [dbo].[Anuncios]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Anuncios](
	[id_anuncio] [int] IDENTITY(1,1) NOT NULL,
	[titulo] [nvarchar](200) NULL,
	[mensaje] [nvarchar](max) NOT NULL,
	[fecha_publicacion] [datetime] NOT NULL,
	[activo] [bit] NOT NULL,
	[id_usuario_creacion] [int] NOT NULL,
	[id_usuario_modificacion] [int] NULL,
	[fecha_modificacion] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id_anuncio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Auditoria]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Auditoria](
	[id_auditoria] [int] IDENTITY(1,1) NOT NULL,
	[tabla_afectada] [nvarchar](50) NOT NULL,
	[id_registro] [int] NOT NULL,
	[tipo_accion] [nvarchar](20) NOT NULL,
	[valores_anteriores] [nvarchar](max) NULL,
	[valores_nuevos] [nvarchar](max) NULL,
	[fecha_cambio] [datetime] NULL,
	[usuario_modificador] [nvarchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_auditoria] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Departamentos]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Departamentos](
	[id_departamento] [int] IDENTITY(1,1) NOT NULL,
	[nombre] [nvarchar](100) NOT NULL,
	[codigo_departamento]  AS ('Depto'+right('000'+CONVERT([varchar],[id_departamento]),(3))) PERSISTED,
PRIMARY KEY CLUSTERED 
(
	[id_departamento] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Empleados]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Empleados](
	[id_empleado] [int] IDENTITY(1,1) NOT NULL,
	[nombre] [nvarchar](100) NOT NULL,
	[apellido] [nvarchar](100) NULL,
	[correo] [nvarchar](100) NOT NULL,
	[telefono] [nvarchar](15) NULL,
	[id_usuario] [int] NULL,
	[id_departamento] [int] NULL,
	[cargo] [nvarchar](50) NOT NULL,
	[salario] [decimal](10, 2) NOT NULL,
	[fecha_ingreso] [date] NOT NULL,
	[fecha_finalizacion] [date] NULL,
	[TipoEmpleado] [nvarchar](20) NOT NULL,
	[Comentario] [nvarchar](255) NULL,
	[id_supervisor_departamento] [int] NULL,
	[direccion] [nvarchar](255) NULL,
	[genero] [nvarchar](20) NULL,
	[fecha_nacimiento] [date] NULL,
	[codigo_empleado]  AS ('Emp'+right('00000'+CONVERT([varchar](10),[id_empleado]),(5))) PERSISTED,
PRIMARY KEY CLUSTERED 
(
	[id_empleado] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Evaluaciones]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Evaluaciones](
	[id_evaluacion] [int] IDENTITY(1,1) NOT NULL,
	[id_empleado] [int] NOT NULL,
	[fecha_evaluacion] [date] NOT NULL,
	[id_supervisor] [int] NULL,
	[resultado_promedio] [decimal](5, 2) NULL,
	[comentarios_supervisor] [nvarchar](max) NULL,
	[id_periodo] [int] NOT NULL,
	[finalizada] [bit] NOT NULL,
	[EvaluadaSupervisor] [bit] NOT NULL,
	[EvaluadoPor] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id_evaluacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EvaluacionesPreguntas]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EvaluacionesPreguntas](
	[id_evaluacion] [int] NOT NULL,
	[id_pregunta] [int] NOT NULL,
	[puntaje_empleado] [int] NOT NULL,
	[puntaje_supervisor] [int] NOT NULL,
	[comentario_empleado] [nvarchar](max) NULL,
	[comentario_supervisor] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[id_evaluacion] ASC,
	[id_pregunta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Mensajes]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Mensajes](
	[id_mensaje] [int] IDENTITY(1,1) NOT NULL,
	[id_emisor] [int] NOT NULL,
	[id_receptor] [int] NOT NULL,
	[mensaje] [nvarchar](max) NOT NULL,
	[fecha_envio] [datetime] NOT NULL,
	[leido] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_mensaje] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Notificaciones]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Notificaciones](
	[id_notificacion] [int] IDENTITY(1,1) NOT NULL,
	[id_empleado] [int] NOT NULL,
	[mensaje] [nvarchar](max) NOT NULL,
	[fecha_creacion] [datetime] NULL,
	[leido] [bit] NULL,
	[tipo] [nvarchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_notificacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PeriodosEvaluacion]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PeriodosEvaluacion](
	[id_periodo] [int] IDENTITY(1,1) NOT NULL,
	[anio] [int] NOT NULL,
	[trimestre] [int] NOT NULL,
	[fecha_inicio] [date] NOT NULL,
	[fecha_fin] [date] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_periodo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Permisos]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Permisos](
	[id_permiso] [int] IDENTITY(1,1) NOT NULL,
	[id_empleado] [int] NOT NULL,
	[id_tipo_permiso] [int] NOT NULL,
	[fecha_inicio] [date] NOT NULL,
	[fecha_fin] [date] NULL,
	[estado] [nvarchar](20) NULL,
	[comentarios_empleado] [nvarchar](max) NULL,
	[comentarios_supervisor] [nvarchar](max) NULL,
	[documento] [nvarchar](255) NULL,
	[fecha_solicitud] [datetime] NULL,
	[horas_solicitadas] [int] NULL,
	[revisado_por] [nvarchar](50) NULL,
	[fecha_revisado] [datetime] NULL,
	[dias_AutoAprobados] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_permiso] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Preguntas]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Preguntas](
	[id_pregunta] [int] IDENTITY(1,1) NOT NULL,
	[texto_pregunta] [nvarchar](255) NOT NULL,
	[seccion] [nvarchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_pregunta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PreguntasPeriodos]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreguntasPeriodos](
	[id_pregunta] [int] NOT NULL,
	[id_periodo] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_pregunta] ASC,
	[id_periodo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PreguntasSeguridad]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreguntasSeguridad](
	[id_pregunta_seguridad] [int] IDENTITY(1,1) NOT NULL,
	[pregunta] [nvarchar](255) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_pregunta_seguridad] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SaldoPermisos]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SaldoPermisos](
	[id_saldo] [int] IDENTITY(1,1) NOT NULL,
	[id_empleado] [int] NOT NULL,
	[id_tipo_permiso] [int] NOT NULL,
	[horas_disponibles] [decimal](10, 2) NOT NULL,
	[SaldoDiasReal]  AS ([horas_disponibles]/(8.0)) PERSISTED,
PRIMARY KEY CLUSTERED 
(
	[id_saldo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SupervisoresDepartamento]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SupervisoresDepartamento](
	[id_supervisor_depto] [int] IDENTITY(1,1) NOT NULL,
	[id_empleado] [int] NOT NULL,
	[id_departamento] [int] NOT NULL,
	[codigoSupervisor]  AS ('SupDepto'+right('000'+CONVERT([varchar],[id_supervisor_depto]),(3))) PERSISTED,
PRIMARY KEY CLUSTERED 
(
	[id_supervisor_depto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TiposPermisos]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TiposPermisos](
	[id_tipo_permiso] [int] IDENTITY(1,1) NOT NULL,
	[nombre_permiso] [nvarchar](50) NOT NULL,
	[justificacion] [nvarchar](255) NOT NULL,
	[dias_maximos_anuales] [int] NOT NULL,
	[dias_maximos_mensuales] [int] NULL,
	[requiere_documento] [bit] NULL,
	[codigo_permiso]  AS ('Perm'+right('000'+CONVERT([varchar],[id_tipo_permiso]),(3))) PERSISTED,
PRIMARY KEY CLUSTERED 
(
	[id_tipo_permiso] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Usuarios]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Usuarios](
	[id_usuario] [int] IDENTITY(1,1) NOT NULL,
	[username] [nvarchar](50) NOT NULL,
	[password] [nvarchar](255) NOT NULL,
	[rol] [nvarchar](20) NOT NULL,
	[Estado] [nvarchar](10) NOT NULL,
	[codigo_usuario]  AS ('User'+right('00000'+CONVERT([varchar](10),[id_usuario]),(5))) PERSISTED,
	[id_pregunta_seguridad] [int] NULL,
	[respuesta_seguridad] [nvarchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[id_usuario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
SET IDENTITY_INSERT [dbo].[Anuncios] ON 

INSERT [dbo].[Anuncios] ([id_anuncio], [titulo], [mensaje], [fecha_publicacion], [activo], [id_usuario_creacion], [id_usuario_modificacion], [fecha_modificacion]) VALUES (1, N'Recordatorio', N'Estimados colaboradores! Por favor recordar completar sus autoevaluaciones para el primer trimestre del 2025!', CAST(N'2025-03-30 18:11:10.420' AS DateTime), 0, 10, 1, CAST(N'2025-03-30 19:50:58.583' AS DateTime))
INSERT [dbo].[Anuncios] ([id_anuncio], [titulo], [mensaje], [fecha_publicacion], [activo], [id_usuario_creacion], [id_usuario_modificacion], [fecha_modificacion]) VALUES (3, N'Recordatorio Vacaciones', N'Estimados, por favor recordar ingresar sus vacaciones antes del feriado!', CAST(N'2025-03-30 18:49:32.063' AS DateTime), 1, 10, 1, CAST(N'2025-03-30 19:51:15.330' AS DateTime))
SET IDENTITY_INSERT [dbo].[Anuncios] OFF
SET IDENTITY_INSERT [dbo].[Auditoria] ON 

INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (1, N'Empleados', 1011, N'INSERT', NULL, N'1011MarieMaziermmazier@email.com9999-99993Asistente de Finanzas30000.002024-10-07InternoEmp01011', CAST(N'2025-03-25 00:36:13.440' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (2, N'Empleados', 1012, N'INSERT', NULL, N'1012VictoriaPadillavpadilla@email.com9999-99998Asistente Operativo25000.002024-05-06InternoEmp01012', CAST(N'2025-03-25 00:42:37.540' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (3, N'Empleados', 1012, N'UPDATE', N'1012VictoriaPadillavpadilla@email.com9999-99998Asistente Operativo25000.002024-05-06InternoEmp01012', N'1012VictoriaPadillavpadilla@email.com9999-99998Asistente Operaciones25000.002024-05-06InternoEmp01012', CAST(N'2025-03-25 00:44:33.777' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (4, N'Empleados', 1012, N'UPDATE', N'1012VictoriaPadillavpadilla@email.com9999-99998Asistente Operaciones25000.002024-05-06InternoEmp01012', N'1012VictoriaPadillavpadilla@email.com9999-99998Asistente Operaciones25000.002024-05-06InternoEmp01012', CAST(N'2025-03-25 00:44:33.780' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (5, N'Empleados', 1013, N'INSERT', NULL, N'1013JoseArdonjardon@email.com9999-99994Asistente de Licitaciones23000.002024-11-04InternoEmp01013', CAST(N'2025-03-25 00:47:20.857' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (6, N'Empleados', 1014, N'INSERT', NULL, N'1014AlejandraRiveraarivera@email.com9999-99998Asistente Operativo y Logistica28000.002024-08-05InternoEmp01014', CAST(N'2025-03-25 00:50:04.340' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (7, N'Empleados', 1015, N'INSERT', NULL, N'1015DavidMartinezdmartinez@email.com9999-99993Asistente Financiero25000.002025-01-13InternoEmp01015', CAST(N'2025-03-25 00:53:58.530' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (8, N'Usuarios', 1015, N'INSERT', NULL, N'1015mmaziere7be39b0a702945ccc80f678c0b512bc99054c818c3c666b08d24096a39ce090empleadoActivoUser01015', CAST(N'2025-03-25 00:59:22.943' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (9, N'Empleados', 1011, N'UPDATE', N'1011MarieMaziermmazier@email.com9999-99993Asistente de Finanzas30000.002024-10-07InternoEmp01011', N'1011MarieMaziermmazier@email.com9999-999910153Asistente de Finanzas30000.002024-10-07InternoEmp01011', CAST(N'2025-03-25 00:59:22.957' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (10, N'Usuarios', 1016, N'INSERT', NULL, N'1016vpadilla104a41cc37911fdeec9eb9174acbb5aa7b91ef1e89c6adb923f8ff79dd6212c0empleadoActivoUser01016', CAST(N'2025-03-25 00:59:54.880' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (11, N'Empleados', 1012, N'UPDATE', N'1012VictoriaPadillavpadilla@email.com9999-99998Asistente Operaciones25000.002024-05-06InternoEmp01012', N'1012VictoriaPadillavpadilla@email.com9999-999910168Asistente Operaciones25000.002024-05-06InternoEmp01012', CAST(N'2025-03-25 00:59:54.887' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (12, N'Usuarios', 1017, N'INSERT', NULL, N'1017jardonb4688d2deeeee592c5d6d985ef05852c609fe766927de0181cc5ccc254137d23empleadoActivoUser01017', CAST(N'2025-03-25 01:00:13.133' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (13, N'Empleados', 1013, N'UPDATE', N'1013JoseArdonjardon@email.com9999-99994Asistente de Licitaciones23000.002024-11-04InternoEmp01013', N'1013JoseArdonjardon@email.com9999-999910174Asistente de Licitaciones23000.002024-11-04InternoEmp01013', CAST(N'2025-03-25 01:00:13.150' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (14, N'Usuarios', 1018, N'INSERT', NULL, N'1018ariverae0b96409b5609c5a1015c3aa05362604317284538d096efdd1f0d25343fe1717empleadoActivoUser01018', CAST(N'2025-03-25 01:00:28.470' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (15, N'Empleados', 1014, N'UPDATE', N'1014AlejandraRiveraarivera@email.com9999-99998Asistente Operativo y Logistica28000.002024-08-05InternoEmp01014', N'1014AlejandraRiveraarivera@email.com9999-999910188Asistente Operativo y Logistica28000.002024-08-05InternoEmp01014', CAST(N'2025-03-25 01:00:28.480' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (16, N'Usuarios', 1019, N'INSERT', NULL, N'1019dmartinezff2583c134e394b1b166f8b28c2fa228ac6ab298b83a0912c6a21235ca2f0bf0empleadoActivoUser01019', CAST(N'2025-03-25 01:01:21.530' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (17, N'Empleados', 1015, N'UPDATE', N'1015DavidMartinezdmartinez@email.com9999-99993Asistente Financiero25000.002025-01-13InternoEmp01015', N'1015DavidMartinezdmartinez@email.com9999-999910193Asistente Financiero25000.002025-01-13InternoEmp01015', CAST(N'2025-03-25 01:01:21.543' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (18, N'TiposPermisos', 4, N'INSERT', NULL, N'4MaternidadCódigo de Trabajo de Honduras, Artículo 135 - descanso forzoso, durante las cuatro (4) semanas que precedan al parto y las seis (6) que le sigan501Perm004', CAST(N'2025-03-25 19:34:54.473' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (19, N'TiposPermisos', 5, N'INSERT', NULL, N'5Enfermedad sin incapacidadDeterminado por la empresa. Empleado puede ausentarse sin constancia médica.30Perm005', CAST(N'2025-03-25 19:50:46.327' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (20, N'TiposPermisos', 6, N'INSERT', NULL, N'6Enfermedad con IncapacidadDerecho a ausentarse por enfermedad con incapacidad médica está regulado en los artículos 100 y 104 del Código de Trabajo.1201Perm006', CAST(N'2025-03-25 19:53:39.203' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (21, N'TiposPermisos', 7, N'INSERT', NULL, N'7Asunto personal o familiarLicencia determinado por la empresa. Presentar documentación o justificación si es posible.1521Perm007', CAST(N'2025-03-25 19:57:24.427' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (22, N'TiposPermisos', 5, N'UPDATE', N'5Enfermedad sin incapacidadDeterminado por la empresa. Empleado puede ausentarse sin constancia médica.30Perm005', N'5Enfermedad sin IncapacidadDeterminado por la empresa. Empleado puede ausentarse sin constancia médica.30Perm005', CAST(N'2025-03-25 19:57:58.063' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (23, N'TiposPermisos', 8, N'INSERT', NULL, N'8AsuetoDeterminado por la empresa530Perm008', CAST(N'2025-03-27 10:41:33.980' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (24, N'TiposPermisos', 8, N'UPDATE', N'8AsuetoDeterminado por la empresa530Perm008', N'8AsuetoDeterminado por la empresa. Usar solamente con previa autorización por parte de gerencia.530Perm008', CAST(N'2025-03-27 10:42:36.430' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (25, N'SaldoPermisos', 2, N'UPDATE', N'27132.004.000000', N'27140.005.000000', CAST(N'2025-03-27 12:08:40.040' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (26, N'Permisos', 2019, N'INSERT', NULL, N'2019782025-04-212025-04-21pendiente2025-03-27T12:36:56.13380', CAST(N'2025-03-27 12:36:56.140' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (27, N'Permisos', 2019, N'UPDATE', N'2019782025-04-212025-04-21pendiente2025-03-27T12:36:56.13380', N'2019782025-04-212025-04-21aprobadoAprobado automáticamente. Días restantes para auto aprobar: 2.2025-03-27T12:36:56.13382025-03-27T12:36:56.1601', CAST(N'2025-03-27 12:36:56.177' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (28, N'SaldoPermisos', 1004, N'INSERT', NULL, N'10047832.004.000000', CAST(N'2025-03-27 12:36:56.253' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (29, N'Permisos', 2020, N'INSERT', NULL, N'2020782025-04-232025-04-25pendiente2025-03-27T12:40:28.740240', CAST(N'2025-03-27 12:40:28.747' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (30, N'Permisos', 2020, N'UPDATE', N'2020782025-04-232025-04-25pendiente2025-03-27T12:40:28.740240', N'2020782025-04-232025-04-25aprobadoAprobado automáticamente. Días restantes para auto aprobar: 0.2025-03-27T12:40:28.740242025-03-27T12:40:28.7802', CAST(N'2025-03-27 12:40:28.790' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (31, N'SaldoPermisos', 1004, N'UPDATE', N'10047832.004.000000', N'1004788.001.000000', CAST(N'2025-03-27 12:40:28.823' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (32, N'Permisos', 2021, N'INSERT', NULL, N'2021782025-04-282025-04-28pendiente2025-03-27T12:41:40.84380', CAST(N'2025-03-27 12:41:40.850' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (33, N'Permisos', 2021, N'UPDATE', N'2021782025-04-282025-04-28pendiente2025-03-27T12:41:40.84380', N'2021782025-04-282025-04-28pendiente2025-03-27T12:41:40.84380', CAST(N'2025-03-27 12:41:40.880' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (34, N'SaldoPermisos', 1004, N'UPDATE', N'1004788.001.000000', N'1004780.000.000000', CAST(N'2025-03-27 12:41:40.900' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (35, N'SaldoPermisos', 1004, N'UPDATE', N'1004780.000.000000', N'10047824.003.000000', CAST(N'2025-03-27 13:33:04.920' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (36, N'Permisos', 2020, N'DELETE', N'2020782025-04-232025-04-25aprobadoAprobado automáticamente. Días restantes para auto aprobar: 0.2025-03-27T12:40:28.740242025-03-27T12:40:28.7802', NULL, CAST(N'2025-03-27 13:33:04.930' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (37, N'SaldoPermisos', 1004, N'UPDATE', N'10047824.003.000000', N'10047832.004.000000', CAST(N'2025-03-27 13:33:11.267' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (38, N'Permisos', 2019, N'DELETE', N'2019782025-04-212025-04-21aprobadoAprobado automáticamente. Días restantes para auto aprobar: 2.2025-03-27T12:36:56.13382025-03-27T12:36:56.1601', NULL, CAST(N'2025-03-27 13:33:11.270' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (39, N'SaldoPermisos', 1004, N'UPDATE', N'10047832.004.000000', N'10047840.005.000000', CAST(N'2025-03-27 13:33:20.053' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (40, N'Permisos', 2021, N'DELETE', N'2021782025-04-282025-04-28pendiente2025-03-27T12:41:40.84380', NULL, CAST(N'2025-03-27 13:33:20.053' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (41, N'Permisos', 2022, N'INSERT', NULL, N'2022782025-04-252025-04-25pendiente2025-03-27T13:33:51.87080', CAST(N'2025-03-27 13:33:51.880' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (42, N'Permisos', 2022, N'UPDATE', N'2022782025-04-252025-04-25pendiente2025-03-27T13:33:51.87080', N'2022782025-04-252025-04-25aprobadoAprobado automáticamente. Días restantes para auto aprobar: 2.2025-03-27T13:33:51.87082025-03-27T13:33:51.9101', CAST(N'2025-03-27 13:33:51.927' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (43, N'SaldoPermisos', 1004, N'UPDATE', N'10047840.005.000000', N'10047832.004.000000', CAST(N'2025-03-27 13:33:51.990' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (44, N'Permisos', 2023, N'INSERT', NULL, N'2023782025-04-212025-04-23pendiente2025-03-27T13:34:17.030240', CAST(N'2025-03-27 13:34:17.030' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (45, N'Permisos', 2023, N'UPDATE', N'2023782025-04-212025-04-23pendiente2025-03-27T13:34:17.030240', N'2023782025-04-212025-04-23aprobadoAprobado automáticamente. Días restantes para auto aprobar: 0.2025-03-27T13:34:17.030242025-03-27T13:34:17.0472', CAST(N'2025-03-27 13:34:17.047' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (46, N'SaldoPermisos', 1004, N'UPDATE', N'10047832.004.000000', N'1004788.001.000000', CAST(N'2025-03-27 13:34:17.057' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (47, N'SaldoPermisos', 1004, N'UPDATE', N'1004788.001.000000', N'10047832.004.000000', CAST(N'2025-03-27 13:37:34.683' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (48, N'Permisos', 2023, N'DELETE', N'2023782025-04-212025-04-23aprobadoAprobado automáticamente. Días restantes para auto aprobar: 0.2025-03-27T13:34:17.030242025-03-27T13:34:17.0472', NULL, CAST(N'2025-03-27 13:37:34.697' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (49, N'SaldoPermisos', 1004, N'UPDATE', N'10047832.004.000000', N'10047840.005.000000', CAST(N'2025-03-27 13:37:40.357' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (50, N'Permisos', 2022, N'DELETE', N'2022782025-04-252025-04-25aprobadoAprobado automáticamente. Días restantes para auto aprobar: 2.2025-03-27T13:33:51.87082025-03-27T13:33:51.9101', NULL, CAST(N'2025-03-27 13:37:40.363' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (51, N'Permisos', 2024, N'INSERT', NULL, N'2024782025-04-042025-04-04pendiente2025-03-27T14:11:07.92080', CAST(N'2025-03-27 14:11:07.930' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (52, N'Permisos', 2024, N'UPDATE', N'2024782025-04-042025-04-04pendiente2025-03-27T14:11:07.92080', N'2024782025-04-042025-04-04aprobadoAprobado automáticamente. Días restantes para auto aprobar: 2.2025-03-27T14:11:07.92082025-03-27T14:11:07.9531', CAST(N'2025-03-27 14:11:07.970' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (53, N'SaldoPermisos', 1004, N'UPDATE', N'10047840.005.000000', N'10047832.004.000000', CAST(N'2025-03-27 14:11:08.023' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (54, N'Permisos', 2025, N'INSERT', NULL, N'2025782025-04-232025-04-25pendiente2025-03-27T14:12:52.970240', CAST(N'2025-03-27 14:12:52.977' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (55, N'Permisos', 2025, N'UPDATE', N'2025782025-04-232025-04-25pendiente2025-03-27T14:12:52.970240', N'2025782025-04-232025-04-25aprobadoAprobado automáticamente. Días restantes para auto aprobar: 0.2025-03-27T14:12:52.970242025-03-27T14:12:52.9972', CAST(N'2025-03-27 14:12:53.013' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (56, N'SaldoPermisos', 1004, N'UPDATE', N'10047832.004.000000', N'1004788.001.000000', CAST(N'2025-03-27 14:12:53.050' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (57, N'SaldoPermisos', 1004, N'UPDATE', N'1004788.001.000000', N'10047832.004.000000', CAST(N'2025-03-27 14:15:06.610' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (58, N'Permisos', 2025, N'DELETE', N'2025782025-04-232025-04-25aprobadoAprobado automáticamente. Días restantes para auto aprobar: 0.2025-03-27T14:12:52.970242025-03-27T14:12:52.9972', NULL, CAST(N'2025-03-27 14:15:06.623' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (59, N'SaldoPermisos', 1004, N'UPDATE', N'10047832.004.000000', N'10047840.005.000000', CAST(N'2025-03-27 14:15:09.883' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (60, N'Permisos', 2024, N'DELETE', N'2024782025-04-042025-04-04aprobadoAprobado automáticamente. Días restantes para auto aprobar: 2.2025-03-27T14:11:07.92082025-03-27T14:11:07.9531', NULL, CAST(N'2025-03-27 14:15:09.887' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (61, N'Permisos', 2026, N'INSERT', NULL, N'2026782025-04-222025-04-25pendiente2025-03-27T14:58:22.280320', CAST(N'2025-03-27 14:58:22.287' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (62, N'Permisos', 2026, N'UPDATE', N'2026782025-04-222025-04-25pendiente2025-03-27T14:58:22.280320', N'2026782025-04-222025-04-25aprobadoAprobado automáticamente. Días restantes para auto aprobar: 0.2025-03-27T14:58:22.280322025-03-27T14:58:22.3173', CAST(N'2025-03-27 14:58:22.343' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (63, N'SaldoPermisos', 1004, N'UPDATE', N'10047840.005.000000', N'1004788.001.000000', CAST(N'2025-03-27 14:58:22.380' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (64, N'Permisos', 2027, N'INSERT', NULL, N'2027782025-04-182025-04-18pendiente2025-03-27T14:59:09.57380', CAST(N'2025-03-27 14:59:09.573' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (65, N'Permisos', 2027, N'UPDATE', N'2027782025-04-182025-04-18pendiente2025-03-27T14:59:09.57380', N'2027782025-04-182025-04-18pendiente2025-03-27T14:59:09.57380', CAST(N'2025-03-27 14:59:09.577' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (66, N'SaldoPermisos', 1004, N'UPDATE', N'1004788.001.000000', N'1004780.000.000000', CAST(N'2025-03-27 14:59:09.580' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (67, N'SaldoPermisos', 1004, N'UPDATE', N'1004780.000.000000', N'1004788.001.000000', CAST(N'2025-03-27 14:59:55.357' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (68, N'Permisos', 2027, N'DELETE', N'2027782025-04-182025-04-18pendiente2025-03-27T14:59:09.57380', NULL, CAST(N'2025-03-27 14:59:55.370' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (69, N'SaldoPermisos', 1004, N'UPDATE', N'1004788.001.000000', N'10047840.005.000000', CAST(N'2025-03-27 15:00:01.403' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (70, N'Permisos', 2026, N'DELETE', N'2026782025-04-222025-04-25aprobadoAprobado automáticamente. Días restantes para auto aprobar: 0.2025-03-27T14:58:22.280322025-03-27T14:58:22.3173', NULL, CAST(N'2025-03-27 15:00:01.407' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (71, N'Permisos', 2028, N'INSERT', NULL, N'2028782025-04-212025-04-21pendiente2025-03-27T15:14:51.45080', CAST(N'2025-03-27 15:14:51.460' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (72, N'Permisos', 2028, N'UPDATE', N'2028782025-04-212025-04-21pendiente2025-03-27T15:14:51.45080', N'2028782025-04-212025-04-21aprobadoAprobado automáticamente. Días restantes para auto aprobar: 2.2025-03-27T15:14:51.45082025-03-27T15:14:51.4801', CAST(N'2025-03-27 15:14:51.500' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (73, N'SaldoPermisos', 1004, N'UPDATE', N'10047840.005.000000', N'10047832.004.000000', CAST(N'2025-03-27 15:14:51.540' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (74, N'Permisos', 2029, N'INSERT', NULL, N'2029782025-04-172025-04-18pendiente2025-03-27T15:16:22.683160', CAST(N'2025-03-27 15:16:22.690' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (75, N'Permisos', 2029, N'UPDATE', N'2029782025-04-172025-04-18pendiente2025-03-27T15:16:22.683160', N'2029782025-04-172025-04-18aprobadoAprobado automáticamente. Días restantes para auto aprobar: 0.2025-03-27T15:16:22.683162025-03-27T15:16:22.7032', CAST(N'2025-03-27 15:16:22.713' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (76, N'SaldoPermisos', 1004, N'UPDATE', N'10047832.004.000000', N'10047816.002.000000', CAST(N'2025-03-27 15:16:22.753' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (77, N'Permisos', 2030, N'INSERT', NULL, N'2030782025-05-052025-05-05pendiente2025-03-27T15:17:16.94780', CAST(N'2025-03-27 15:17:16.957' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (78, N'Permisos', 2030, N'UPDATE', N'2030782025-05-052025-05-05pendiente2025-03-27T15:17:16.94780', N'2030782025-05-052025-05-05pendiente2025-03-27T15:17:16.94780', CAST(N'2025-03-27 15:17:16.980' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (79, N'SaldoPermisos', 1004, N'UPDATE', N'10047816.002.000000', N'1004788.001.000000', CAST(N'2025-03-27 15:17:17.003' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (80, N'SaldoPermisos', 1004, N'UPDATE', N'1004788.001.000000', N'10047816.002.000000', CAST(N'2025-03-27 15:27:43.013' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (81, N'Permisos', 2030, N'DELETE', N'2030782025-05-052025-05-05pendiente2025-03-27T15:17:16.94780', NULL, CAST(N'2025-03-27 15:27:43.020' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (82, N'SaldoPermisos', 1004, N'UPDATE', N'10047816.002.000000', N'10047832.004.000000', CAST(N'2025-03-27 15:27:46.083' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (83, N'Permisos', 2029, N'DELETE', N'2029782025-04-172025-04-18aprobadoAprobado automáticamente. Días restantes para auto aprobar: 0.2025-03-27T15:16:22.683162025-03-27T15:16:22.7032', NULL, CAST(N'2025-03-27 15:27:46.097' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (84, N'SaldoPermisos', 1004, N'UPDATE', N'10047832.004.000000', N'10047840.005.000000', CAST(N'2025-03-27 15:27:49.653' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (85, N'Permisos', 2028, N'DELETE', N'2028782025-04-212025-04-21aprobadoAprobado automáticamente. Días restantes para auto aprobar: 2.2025-03-27T15:14:51.45082025-03-27T15:14:51.4801', NULL, CAST(N'2025-03-27 15:27:49.653' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (86, N'Empleados', 5, N'UPDATE', N'5JuanPerezjperez@email.com9999-999994Asesor de Ventas20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', N'5JuanPerezjperez@email.com9999-999994Asesor de Ventas20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', CAST(N'2025-03-27 22:20:39.740' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (87, N'Usuarios', 9, N'UPDATE', N'9jpereza6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43deempleadoActivoUser00009', N'9jpereza6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43deempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-27 22:20:39.770' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (88, N'Usuarios', 9, N'UPDATE', N'9jpereza6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43deempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', N'9jperez491e6cca8596cbcb5aefa0322176abdb9675736d52738271440d8305a2cf0bd4empleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-27 22:48:24.133' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (89, N'Empleados', 5, N'UPDATE', N'5JuanPerezjperez@email.com9999-999994Asesor de Ventas20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', N'5JuanPerezjperez@email.com9999-999994Asesor de Ventas20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', CAST(N'2025-03-27 22:49:12.680' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (90, N'Usuarios', 9, N'UPDATE', N'9jperez491e6cca8596cbcb5aefa0322176abdb9675736d52738271440d8305a2cf0bd4empleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', N'9jpereza6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43deempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-27 22:49:12.700' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (91, N'Usuarios', 9, N'UPDATE', N'9jpereza6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43deempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', N'9jperez6745f09366831cd3ea586ff15b8a778a29cf888008da15d44a1fcc49f36f483eempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-28 00:40:00.650' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (92, N'Empleados', 5, N'UPDATE', N'5JuanPerezjperez@email.com9999-999994Asesor de Ventas20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', N'5JuanPerezjperez@email.com9999-999994Asesor de Ventas20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', CAST(N'2025-03-28 00:41:56.003' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (93, N'Usuarios', 9, N'UPDATE', N'9jperez6745f09366831cd3ea586ff15b8a778a29cf888008da15d44a1fcc49f36f483eempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', N'9jpereza6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43deempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-28 00:41:56.020' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (94, N'Usuarios', 9, N'UPDATE', N'9jpereza6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43deempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', N'9jperez4ba4eb6ef93380f811e1adf3c7bc5546fd8c514618f8c5b8d49fb6c8ae5f7961empleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-28 00:46:42.190' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (95, N'Empleados', 5, N'UPDATE', N'5JuanPerezjperez@email.com9999-999994Asesor de Ventas20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', N'5JuanPerezjperez@email.com9999-999994Asesor de Ventas20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', CAST(N'2025-03-28 00:47:28.050' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (96, N'Usuarios', 9, N'UPDATE', N'9jperez4ba4eb6ef93380f811e1adf3c7bc5546fd8c514618f8c5b8d49fb6c8ae5f7961empleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', N'9jpereza6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43deempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-28 00:47:28.070' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (97, N'Usuarios', 9, N'UPDATE', N'9jpereza6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43deempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', N'9jperez92df823a85219b89a38d9e30793bf344c1d2bb2c5287570726903862ceddbc52empleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-28 00:55:32.593' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (98, N'Empleados', 5, N'UPDATE', N'5JuanPerezjperez@email.com9999-999994Asesor de Ventas20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', N'5JuanPerezjperez@email.com9999-999994Asesor de Ventas20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', CAST(N'2025-03-28 00:56:45.570' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (99, N'Usuarios', 9, N'UPDATE', N'9jperez92df823a85219b89a38d9e30793bf344c1d2bb2c5287570726903862ceddbc52empleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', N'9jpereza6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43deempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-28 00:56:45.587' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
GO
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (100, N'Mensajes', 52, N'INSERT', NULL, N'52101510hola?2025-03-28T16:23:15.9870', CAST(N'2025-03-28 16:23:15.990' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (101, N'Empleados', 1011, N'UPDATE', N'1011MarieMaziermmazier@email.com9999-999910153Asistente de Finanzas30000.002024-10-07InternoEmp01011', N'1011MarieMaziermmazier@email.com9999-999910153Asistente de Finanzas30000.002024-10-07InternoColonia Altos de TrapiceFemenino1990-07-13Emp01011', CAST(N'2025-03-28 16:25:35.530' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (102, N'Usuarios', 1015, N'UPDATE', N'1015mmaziere7be39b0a702945ccc80f678c0b512bc99054c818c3c666b08d24096a39ce090empleadoActivoUser01015', N'1015mmaziere7be39b0a702945ccc80f678c0b512bc99054c818c3c666b08d24096a39ce090empleadoActivoUser010152a671e1605a46713ef7fc2d0dab065ddfe20f2415ae9c724cc039129902d885ef', CAST(N'2025-03-28 16:25:35.657' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (103, N'Empleados', 6, N'UPDATE', N'6PaolaRamirezpramirez@email.com9999-9999101Gerente de RRHH50000.002023-02-01Interno1Emp00006', N'6PaolaRamirezpramirez@email.com9999-9999101Gerente de RRHH50000.002023-02-01Interno1Colonia TatumblaFemenino1980-02-20Emp00006', CAST(N'2025-03-28 16:33:55.077' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (104, N'Usuarios', 10, N'UPDATE', N'10pramirez7e96a9e995f001a4462e5979ee43c16bc0a3848cc0f232c01cf8d0a8a8652652rhActivoUser00010', N'10pramirez7e96a9e995f001a4462e5979ee43c16bc0a3848cc0f232c01cf8d0a8a8652652rhActivoUser0001029d77a24d0f4c91a2e968ca607e49dd3b15d5489f66a5bc81fa72803b32443419', CAST(N'2025-03-28 16:33:55.097' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (105, N'Empleados', 1007, N'UPDATE', N'1007ErnestoMartinezemartinez@email.com9999-999910112Asistente de TI20000.002024-07-01InternoEmp01007', N'1007ErnestoMartinezemartinez@email.com9999-999910112Asistente de TI20000.002024-07-01InternoColonia SateliteMasculino1995-05-22Emp01007', CAST(N'2025-03-28 16:35:11.180' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (106, N'Usuarios', 1011, N'UPDATE', N'1011emartinez240ad18c901b1f419030071f2e737b957312ab082ca3b134a743cc0d2dcb6c4fempleadoActivoUser01011', N'1011emartinez240ad18c901b1f419030071f2e737b957312ab082ca3b134a743cc0d2dcb6c4fempleadoActivoUser010112a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-28 16:35:11.200' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (107, N'Empleados', 1008, N'UPDATE', N'1008PedroPerezpperez@email.com9999-999910124Gerente de Compras25000.002024-02-05Interno4Emp01008', N'1008PedroPerezpperez@email.com9999-999910124Gerente de Compras25000.002024-02-05Interno4Colonia LomasMasculino1975-04-18Emp01008', CAST(N'2025-03-28 16:36:08.010' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (108, N'Usuarios', 1012, N'UPDATE', N'1012pperez00767e8185d25da7789acb36c1f0dc06fd8c8ad49bc5c764e65c7e64e1a75415supervisorActivoUser01012', N'1012pperez00767e8185d25da7789acb36c1f0dc06fd8c8ad49bc5c764e65c7e64e1a75415supervisorActivoUser010122a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-28 16:36:08.027' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (109, N'Empleados', 1009, N'UPDATE', N'1009ManuelPoncemponce@email.com9999-999910133Gerente de Finanzas50000.002024-04-08Interno3Emp01009', N'1009ManuelPoncemponce@email.com9999-999910133Gerente de Finanzas50000.002024-04-08Interno3Colonia Lomas del MayabMasculino1985-08-15Emp01009', CAST(N'2025-03-28 16:37:13.723' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (110, N'Usuarios', 1013, N'UPDATE', N'1013mponce1cfaaebe60124777d1e9bd8744ea9e98a5ce4736470a789322af666e9f19d0fesupervisorActivoUser01013', N'1013mponce1cfaaebe60124777d1e9bd8744ea9e98a5ce4736470a789322af666e9f19d0fesupervisorActivoUser010132a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-28 16:37:13.753' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (111, N'Empleados', 1010, N'UPDATE', N'1010NataliaJimeneznjimenez@email.com9999-999910148Gerente de Operaciones45000.002025-01-20Interno8Emp01010', N'1010NataliaJimeneznjimenez@email.com9999-999910148Gerente de Operaciones45000.002025-01-20Interno8Colonia VieraFemenino1980-02-24Emp01010', CAST(N'2025-03-28 16:38:21.977' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (112, N'Usuarios', 1014, N'UPDATE', N'1014njimenez2769f6ea2a49744ff6b4ab2b294aa13d71c1761cf5775de262709a4ae2c118a8supervisorActivoUser01014', N'1014njimenez2769f6ea2a49744ff6b4ab2b294aa13d71c1761cf5775de262709a4ae2c118a8supervisorActivoUser0101429d77a24d0f4c91a2e968ca607e49dd3b15d5489f66a5bc81fa72803b32443419', CAST(N'2025-03-28 16:38:22.007' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (113, N'Empleados', 1012, N'UPDATE', N'1012VictoriaPadillavpadilla@email.com9999-999910168Asistente Operaciones25000.002024-05-06InternoEmp01012', N'1012VictoriaPadillavpadilla@email.com9999-999910168Asistente Operaciones25000.002024-05-06InternoColonia Santa LuciaFemenino1985-06-09Emp01012', CAST(N'2025-03-28 16:39:17.410' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (114, N'Usuarios', 1016, N'UPDATE', N'1016vpadilla104a41cc37911fdeec9eb9174acbb5aa7b91ef1e89c6adb923f8ff79dd6212c0empleadoActivoUser01016', N'1016vpadilla104a41cc37911fdeec9eb9174acbb5aa7b91ef1e89c6adb923f8ff79dd6212c0empleadoActivoUser0101629d77a24d0f4c91a2e968ca607e49dd3b15d5489f66a5bc81fa72803b32443419', CAST(N'2025-03-28 16:39:17.427' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (115, N'Empleados', 1013, N'UPDATE', N'1013JoseArdonjardon@email.com9999-999910174Asistente de Licitaciones23000.002024-11-04InternoEmp01013', N'1013JoseArdonjardon@email.com9999-999910174Asistente de Licitaciones23000.002024-11-04InternoColonia AmericaMasculino2000-11-26Emp01013', CAST(N'2025-03-28 16:40:07.267' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (116, N'Usuarios', 1017, N'UPDATE', N'1017jardonb4688d2deeeee592c5d6d985ef05852c609fe766927de0181cc5ccc254137d23empleadoActivoUser01017', N'1017jardonb4688d2deeeee592c5d6d985ef05852c609fe766927de0181cc5ccc254137d23empleadoActivoUser010172a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-28 16:40:07.283' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (117, N'Empleados', 1014, N'UPDATE', N'1014AlejandraRiveraarivera@email.com9999-999910188Asistente Operativo y Logistica28000.002024-08-05InternoEmp01014', N'1014AlejandraRiveraarivera@email.com9999-999910188Asistente Operativo y Logistica28000.002024-08-05InternoColonia Villa OlimpicaFemenino1995-09-12Emp01014', CAST(N'2025-03-28 16:41:33.950' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (118, N'Usuarios', 1018, N'UPDATE', N'1018ariverae0b96409b5609c5a1015c3aa05362604317284538d096efdd1f0d25343fe1717empleadoActivoUser01018', N'1018ariverae0b96409b5609c5a1015c3aa05362604317284538d096efdd1f0d25343fe1717empleadoActivoUser0101829d77a24d0f4c91a2e968ca607e49dd3b15d5489f66a5bc81fa72803b32443419', CAST(N'2025-03-28 16:41:33.967' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (119, N'Empleados', 1015, N'UPDATE', N'1015DavidMartinezdmartinez@email.com9999-999910193Asistente Financiero25000.002025-01-13InternoEmp01015', N'1015DavidMartinezdmartinez@email.com9999-999910193Asistente Financiero25000.002025-01-13InternoColonia MatamorosMasculino1997-10-20Emp01015', CAST(N'2025-03-28 16:42:24.790' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (120, N'Usuarios', 1019, N'UPDATE', N'1019dmartinezff2583c134e394b1b166f8b28c2fa228ac6ab298b83a0912c6a21235ca2f0bf0empleadoActivoUser01019', N'1019dmartinezff2583c134e394b1b166f8b28c2fa228ac6ab298b83a0912c6a21235ca2f0bf0empleadoActivoUser010192a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-03-28 16:42:24.813' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (121, N'Empleados', 2, N'UPDATE', N'2DavidCuellardcuellar@email.com9999-999962Gerente50000.002024-02-04Interno2Emp00002', N'2DavidCuellardcuellar@email.com9999-999962Gerente50000.002024-02-04Interno2Colonia TepeyacMasculino1982-07-20Emp00002', CAST(N'2025-03-28 16:43:49.620' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (122, N'Usuarios', 6, N'UPDATE', N'6dcuellar2f9e00b2753a73089d67ad0351bd2d016823c59ce8e73e27bc9d228ff8bfbbbcsupervisorActivoUser00006', N'6dcuellar2f9e00b2753a73089d67ad0351bd2d016823c59ce8e73e27bc9d228ff8bfbbbcsupervisorActivoUser000062f648ec6d69fb3828b7b3fae3c0504083bcaf919a904c3ad9f410674eff899620', CAST(N'2025-03-28 16:43:49.640' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (123, N'Permisos', 2031, N'INSERT', NULL, N'2031100712025-09-122025-09-16pendienteVacaciones.2025-03-28T19:23:08.693160', CAST(N'2025-03-28 19:23:08.703' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (124, N'SaldoPermisos', 1002, N'UPDATE', N'10021007156.007.000000', N'10021007140.005.000000', CAST(N'2025-03-28 19:23:08.750' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (125, N'Permisos', 2032, N'INSERT', NULL, N'2032100712025-10-012025-10-06pendientevacaciones por viaje.2025-03-28T19:25:16.270240', CAST(N'2025-03-28 19:25:16.277' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (126, N'SaldoPermisos', 1002, N'UPDATE', N'10021007140.005.000000', N'10021007116.002.000000', CAST(N'2025-03-28 19:25:16.303' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (127, N'Mensajes', 53, N'INSERT', NULL, N'5310116hola estimado, ya ingrese las vacaciones que deseo tomar en octubre.2025-03-28T19:26:14.7000', CAST(N'2025-03-28 19:26:14.703' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (128, N'Permisos', 2032, N'UPDATE', N'2032100712025-10-012025-10-06pendientevacaciones por viaje.2025-03-28T19:25:16.270240', N'2032100712025-10-012025-10-06aprobadovacaciones por viaje.listo que disfrute.2025-03-28T19:25:16.27024dcuellar2025-03-28T19:27:17.8770', CAST(N'2025-03-28 19:27:17.897' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (129, N'Permisos', 2017, N'UPDATE', N'2017100712025-04-042025-04-04pendiente2025-03-25T23:59:22.81780', N'2017100712025-04-042025-04-04aprobadolisto.2025-03-25T23:59:22.8178dcuellar2025-03-28T19:27:37.5300', CAST(N'2025-03-28 19:27:37.543' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (130, N'Mensajes', 53, N'UPDATE', N'5310116hola estimado, ya ingrese las vacaciones que deseo tomar en octubre.2025-03-28T19:26:14.7000', N'5310116hola estimado, ya ingrese las vacaciones que deseo tomar en octubre.2025-03-28T19:26:14.7001', CAST(N'2025-03-28 19:27:40.457' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (131, N'Mensajes', 54, N'INSERT', NULL, N'5461011aprobadas.2025-03-28T19:27:46.5970', CAST(N'2025-03-28 19:27:46.600' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (132, N'SaldoPermisos', 1002, N'UPDATE', N'10021007116.002.000000', N'10021007132.004.000000', CAST(N'2025-03-28 19:28:11.003' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (133, N'Permisos', 2031, N'DELETE', N'2031100712025-09-122025-09-16pendienteVacaciones.2025-03-28T19:23:08.693160', NULL, CAST(N'2025-03-28 19:28:11.017' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (134, N'Mensajes', 54, N'UPDATE', N'5461011aprobadas.2025-03-28T19:27:46.5970', N'5461011aprobadas.2025-03-28T19:27:46.5971', CAST(N'2025-03-28 19:28:38.870' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (135, N'TiposPermisos', 4, N'UPDATE', N'4MaternidadCódigo de Trabajo de Honduras, Artículo 135 - descanso forzoso, durante las cuatro (4) semanas que precedan al parto y las seis (6) que le sigan501Perm004', N'4MaternidadCódigo de Trabajo de Honduras, Artículo 135 - descanso forzoso, durante las cuatro (4) semanas que precedan al parto y las seis (6) que le sigan701Perm004', CAST(N'2025-03-28 21:49:34.567' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (136, N'Mensajes', 52, N'UPDATE', N'52101510hola?2025-03-28T16:23:15.9870', N'52101510hola?2025-03-28T16:23:15.9871', CAST(N'2025-03-28 21:52:38.497' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (137, N'Empleados', 1016, N'INSERT', NULL, N'1016EsmeraldaPintoepinto@email.com9999-99998Oficial Operativo45000.002025-03-03InternoEmp01016', CAST(N'2025-03-28 22:12:45.247' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (138, N'Usuarios', 1020, N'INSERT', NULL, N'1020epinto65c184997f4a765c37447e2fd72cd4ee4cb766445440c93d5a679fcb877528a4empleadoActivoUser01020', CAST(N'2025-03-28 22:13:44.573' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (139, N'Empleados', 1016, N'UPDATE', N'1016EsmeraldaPintoepinto@email.com9999-99998Oficial Operativo45000.002025-03-03InternoEmp01016', N'1016EsmeraldaPintoepinto@email.com9999-999910208Oficial Operativo45000.002025-03-03InternoEmp01016', CAST(N'2025-03-28 22:13:44.603' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (140, N'Permisos', 2033, N'INSERT', NULL, N'2033101612025-04-112025-04-18pendienteVacaciones por semana santa 20252025-03-28T22:21:23.403240', CAST(N'2025-03-28 22:21:23.417' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (141, N'SaldoPermisos', 1005, N'INSERT', NULL, N'10051016156.007.000000', CAST(N'2025-03-28 22:21:23.513' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (142, N'Mensajes', 55, N'INSERT', NULL, N'5510201019Hi2025-03-28T22:22:49.5800', CAST(N'2025-03-28 22:22:49.587' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (143, N'Empleados', 1016, N'UPDATE', N'1016EsmeraldaPintoepinto@email.com9999-999910208Oficial Operativo45000.002025-03-03InternoEmp01016', N'1016EsmeraldaPintoepinto@email.com9456007210208Oficial Operativo45000.002025-03-03InternoCol El HatilloFemenino1990-09-22Emp01016', CAST(N'2025-03-28 22:24:03.080' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (144, N'Permisos', 2033, N'UPDATE', N'2033101612025-04-112025-04-18pendienteVacaciones por semana santa 20252025-03-28T22:21:23.403240', N'2033101612025-04-112025-04-18aprobadoVacaciones por semana santa 2025aprobado2025-03-28T22:21:23.40324pramirez2025-03-28T22:25:50.5770', CAST(N'2025-03-28 22:25:50.603' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (145, N'Empleados', 5, N'UPDATE', N'5JuanPerezjperez@email.com9999-999994Asesor de Ventas20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', N'5JuanPerezjperez@email.com9999-999994Asistente de Compras20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', CAST(N'2025-03-28 23:32:59.257' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (146, N'Empleados', 5, N'UPDATE', N'5JuanPerezjperez@email.com9999-999994Asistente de Compras20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', N'5JuanPerezjperez@email.com9999-999994Asistente de Compras20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', CAST(N'2025-03-28 23:32:59.263' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (147, N'Anuncios', 1, N'UPDATE', NULL, N'1RecordatorioEstimados colaboradores! Por favor recordar completar sus autoevaluaciones para el primer trimestre del 2025!2025-03-30T18:11:10.42001012025-03-30T19:50:58.583', CAST(N'2025-03-30 19:50:58.600' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (148, N'Anuncios', 3, N'UPDATE', NULL, N'3Recordatorio VacacionesEstimados, por favor recordar ingresar sus vacaciones antes del feriado!2025-03-30T18:49:32.06311012025-03-30T19:51:15.330', CAST(N'2025-03-30 19:51:15.343' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (149, N'Permisos', 2034, N'INSERT', NULL, N'2034512025-04-162025-04-16pendientePor motivo de viaje.2025-04-02T00:24:43.35780', CAST(N'2025-04-02 00:24:43.367' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (150, N'SaldoPermisos', 1, N'UPDATE', N'15132.004.000000', N'15124.003.000000', CAST(N'2025-04-02 00:24:43.440' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (151, N'Empleados', 1017, N'INSERT', NULL, N'1017ThorAdministradortadmin@email.com9999-99992Administrador de Sistema50000.002024-01-08InternoEmp01017', CAST(N'2025-04-02 17:07:34.213' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (152, N'Usuarios', 1021, N'INSERT', NULL, N'1021tadmin5c0db59995b0935755cca73b34fe1feabd855ca69b3257597f2e5dc1ae98d5beadminActivoUser01021', CAST(N'2025-04-02 17:08:36.510' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (153, N'Empleados', 1017, N'UPDATE', N'1017ThorAdministradortadmin@email.com9999-99992Administrador de Sistema50000.002024-01-08InternoEmp01017', N'1017ThorAdministradortadmin@email.com9999-999910212Administrador de Sistema50000.002024-01-08InternoEmp01017', CAST(N'2025-04-02 17:08:36.530' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (154, N'Empleados', 1017, N'UPDATE', N'1017ThorAdministradortadmin@email.com9999-999910212Administrador de Sistema50000.002024-01-08InternoEmp01017', N'1017ThorAdministradortadmin@email.com9999-999910212Administrador de Sistema50000.002024-01-08InternoColonia Roble OesteMasculino1985-07-20Emp01017', CAST(N'2025-04-02 17:10:50.800' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (155, N'Usuarios', 1021, N'UPDATE', N'1021tadmin5c0db59995b0935755cca73b34fe1feabd855ca69b3257597f2e5dc1ae98d5beadminActivoUser01021', N'1021tadmin5c0db59995b0935755cca73b34fe1feabd855ca69b3257597f2e5dc1ae98d5beadminActivoUser010212a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-04-02 17:10:50.823' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (156, N'Usuarios', 9, N'UPDATE', N'9jpereza6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43deempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', N'9jperez7d45b594d709fd0778fb9d56432c2d1eac30495830c750c329f4c41359675b4aempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-04-02 23:12:35.213' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (157, N'Empleados', 5, N'UPDATE', N'5JuanPerezjperez@email.com9999-999994Asistente de Compras20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', N'5JuanPerezjperez@email.com9999-999994Asistente de Compras20000.002025-01-06InternoColonia Kennedy, primera entrada, casa #4Masculino1990-02-12Emp00005', CAST(N'2025-04-02 23:13:13.303' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (158, N'Usuarios', 9, N'UPDATE', N'9jperez7d45b594d709fd0778fb9d56432c2d1eac30495830c750c329f4c41359675b4aempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', N'9jpereza6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43deempleadoActivoUser000092a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-04-02 23:13:13.333' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (159, N'Mensajes', 56, N'INSERT', NULL, N'5696HOLA!2025-04-02T23:13:30.3970', CAST(N'2025-04-02 23:13:30.403' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (160, N'Mensajes', 56, N'UPDATE', N'5696HOLA!2025-04-02T23:13:30.3970', N'5696HOLA!2025-04-02T23:13:30.3971', CAST(N'2025-04-02 23:13:59.270' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (161, N'Mensajes', 57, N'INSERT', NULL, N'5769HOLA!2025-04-02T23:14:03.6170', CAST(N'2025-04-02 23:14:03.617' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (162, N'Empleados', 7, N'UPDATE', N'7JuanaPerezjuanaperez@email.com95490072111Asistente de Recursos Humanos20000.002024-02-05InternoColonia Los RoblesFemenino1990-07-02Emp00007', N'7JuanaPerezjuanaperez@email.com95490072111Asistente de Recursos Humanos20000.002024-02-05InternoColonia El HatilloFemenino1990-07-02Emp00007', CAST(N'2025-04-23 17:46:27.847' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (163, N'Usuarios', 11, N'UPDATE', N'11juanapd649937aeec1bcd91b291e75d2f20cb8572ef35155caf3bd682cfe6bf259f29bempleadoActivoUser00011', N'11juanapd649937aeec1bcd91b291e75d2f20cb8572ef35155caf3bd682cfe6bf259f29bempleadoActivoUser000112a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-04-23 17:46:27.927' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (164, N'Empleados', 7, N'UPDATE', N'7JuanaPerezjuanaperez@email.com95490072111Asistente de Recursos Humanos20000.002024-02-05InternoColonia El HatilloFemenino1990-07-02Emp00007', N'7JuanaPerezjuanaperez@email.com95490072111Asistente de Recursos Humanos20000.002024-02-05InternoColonia Los RoblesFemenino1990-07-02Emp00007', CAST(N'2025-04-23 17:46:48.347' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (165, N'Usuarios', 1021, N'UPDATE', N'1021tadmin5c0db59995b0935755cca73b34fe1feabd855ca69b3257597f2e5dc1ae98d5beadminActivoUser010212a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', N'1021tadmin5c0db59995b0935755cca73b34fe1feabd855ca69b3257597f2e5dc1ae98d5beadminInactivoUser010212a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-04-23 17:51:26.947' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
INSERT [dbo].[Auditoria] ([id_auditoria], [tabla_afectada], [id_registro], [tipo_accion], [valores_anteriores], [valores_nuevos], [fecha_cambio], [usuario_modificador]) VALUES (166, N'Usuarios', 1021, N'UPDATE', N'1021tadmin5c0db59995b0935755cca73b34fe1feabd855ca69b3257597f2e5dc1ae98d5beadminInactivoUser010212a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', N'1021tadmin5c0db59995b0935755cca73b34fe1feabd855ca69b3257597f2e5dc1ae98d5beadminActivoUser010212a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8', CAST(N'2025-04-23 17:52:18.460' AS DateTime), N'DESKTOP-CPNKVLV\Owner')
SET IDENTITY_INSERT [dbo].[Auditoria] OFF
SET ANSI_PADDING ON
SET IDENTITY_INSERT [dbo].[Departamentos] ON 

INSERT [dbo].[Departamentos] ([id_departamento], [nombre]) VALUES (1, N'Recursos Humanos')
INSERT [dbo].[Departamentos] ([id_departamento], [nombre]) VALUES (2, N'TI')
INSERT [dbo].[Departamentos] ([id_departamento], [nombre]) VALUES (3, N'Finanzas')
INSERT [dbo].[Departamentos] ([id_departamento], [nombre]) VALUES (4, N'Compras')
INSERT [dbo].[Departamentos] ([id_departamento], [nombre]) VALUES (8, N'Operaciones')
SET IDENTITY_INSERT [dbo].[Departamentos] OFF
SET ANSI_PADDING OFF
SET ANSI_PADDING ON
SET IDENTITY_INSERT [dbo].[Empleados] ON 

INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (2, N'David', N'Cuellar', N'dcuellar@email.com', N'9999-9999', 6, 2, N'Gerente', CAST(50000.00 AS Decimal(10, 2)), CAST(N'2024-02-04' AS Date), NULL, N'Interno', N'', 2, N'Colonia Tepeyac', N'Masculino', CAST(N'1982-07-20' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (5, N'Juan', N'Perez', N'jperez@email.com', N'9999-9999', 9, 4, N'Asistente de Compras', CAST(20000.00 AS Decimal(10, 2)), CAST(N'2025-01-06' AS Date), NULL, N'Interno', N'', NULL, N'Colonia Kennedy, primera entrada, casa #4', N'Masculino', CAST(N'1990-02-12' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (6, N'Paola', N'Ramirez', N'pramirez@email.com', N'9999-9999', 10, 1, N'Gerente de RRHH', CAST(50000.00 AS Decimal(10, 2)), CAST(N'2023-02-01' AS Date), NULL, N'Interno', N'', 1, N'Colonia Tatumbla', N'Femenino', CAST(N'1980-02-20' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (7, N'Juana', N'Perez', N'juanaperez@email.com', N'95490072', 11, 1, N'Asistente de Recursos Humanos', CAST(20000.00 AS Decimal(10, 2)), CAST(N'2024-02-05' AS Date), NULL, N'Interno', N'', NULL, N'Colonia Los Robles', N'Femenino', CAST(N'1990-07-02' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (1007, N'Ernesto', N'Martinez', N'emartinez@email.com', N'9999-9999', 1011, 2, N'Asistente de TI', CAST(20000.00 AS Decimal(10, 2)), CAST(N'2024-07-01' AS Date), NULL, N'Interno', N'', NULL, N'Colonia Satelite', N'Masculino', CAST(N'1995-05-22' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (1008, N'Pedro', N'Perez', N'pperez@email.com', N'9999-9999', 1012, 4, N'Gerente de Compras', CAST(25000.00 AS Decimal(10, 2)), CAST(N'2024-02-05' AS Date), NULL, N'Interno', N'', 4, N'Colonia Lomas', N'Masculino', CAST(N'1975-04-18' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (1009, N'Manuel', N'Ponce', N'mponce@email.com', N'9999-9999', 1013, 3, N'Gerente de Finanzas', CAST(50000.00 AS Decimal(10, 2)), CAST(N'2024-04-08' AS Date), NULL, N'Interno', N'', 3, N'Colonia Lomas del Mayab', N'Masculino', CAST(N'1985-08-15' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (1010, N'Natalia', N'Jimenez', N'njimenez@email.com', N'9999-9999', 1014, 8, N'Gerente de Operaciones', CAST(45000.00 AS Decimal(10, 2)), CAST(N'2025-01-20' AS Date), NULL, N'Interno', N'', 8, N'Colonia Viera', N'Femenino', CAST(N'1980-02-24' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (1011, N'Marie', N'Mazier', N'mmazier@email.com', N'9999-9999', 1015, 3, N'Asistente de Finanzas', CAST(30000.00 AS Decimal(10, 2)), CAST(N'2024-10-07' AS Date), NULL, N'Interno', N'', NULL, N'Colonia Altos de Trapice', N'Femenino', CAST(N'1990-07-13' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (1012, N'Victoria', N'Padilla', N'vpadilla@email.com', N'9999-9999', 1016, 8, N'Asistente Operaciones', CAST(25000.00 AS Decimal(10, 2)), CAST(N'2024-05-06' AS Date), NULL, N'Interno', N'', NULL, N'Colonia Santa Lucia', N'Femenino', CAST(N'1985-06-09' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (1013, N'Jose', N'Ardon', N'jardon@email.com', N'9999-9999', 1017, 4, N'Asistente de Licitaciones', CAST(23000.00 AS Decimal(10, 2)), CAST(N'2024-11-04' AS Date), NULL, N'Interno', N'', NULL, N'Colonia America', N'Masculino', CAST(N'2000-11-26' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (1014, N'Alejandra', N'Rivera', N'arivera@email.com', N'9999-9999', 1018, 8, N'Asistente Operativo y Logistica', CAST(28000.00 AS Decimal(10, 2)), CAST(N'2024-08-05' AS Date), NULL, N'Interno', N'', NULL, N'Colonia Villa Olimpica', N'Femenino', CAST(N'1995-09-12' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (1015, N'David', N'Martinez', N'dmartinez@email.com', N'9999-9999', 1019, 3, N'Asistente Financiero', CAST(25000.00 AS Decimal(10, 2)), CAST(N'2025-01-13' AS Date), NULL, N'Interno', N'', NULL, N'Colonia Matamoros', N'Masculino', CAST(N'1997-10-20' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (1016, N'Esmeralda', N'Pinto', N'epinto@email.com', N'94560072', 1020, 8, N'Oficial Operativo', CAST(45000.00 AS Decimal(10, 2)), CAST(N'2025-03-03' AS Date), NULL, N'Interno', N'', NULL, N'Col El Hatillo', N'Femenino', CAST(N'1990-09-22' AS Date))
INSERT [dbo].[Empleados] ([id_empleado], [nombre], [apellido], [correo], [telefono], [id_usuario], [id_departamento], [cargo], [salario], [fecha_ingreso], [fecha_finalizacion], [TipoEmpleado], [Comentario], [id_supervisor_departamento], [direccion], [genero], [fecha_nacimiento]) VALUES (1017, N'Thor', N'Administrador', N'tadmin@email.com', N'9999-9999', 1021, 2, N'Administrador de Sistema', CAST(50000.00 AS Decimal(10, 2)), CAST(N'2024-01-08' AS Date), NULL, N'Interno', N'', NULL, N'Colonia Roble Oeste', N'Masculino', CAST(N'1985-07-20' AS Date))
SET IDENTITY_INSERT [dbo].[Empleados] OFF
SET ANSI_PADDING OFF
SET IDENTITY_INSERT [dbo].[Evaluaciones] ON 

INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (3, 7, CAST(N'2025-03-12' AS Date), 6, CAST(43.00 AS Decimal(5, 2)), N'Juana es muy trabajadora y dedicada, ha demostrado en este periodo muy buen desempeño. Puede ir mejorando con las nuevas asignaciones.', 6, 1, 1, N'pramirez')
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (4, 7, CAST(N'2025-03-12' AS Date), NULL, NULL, NULL, 1, 0, 0, NULL)
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (5, 7, CAST(N'2025-03-12' AS Date), 6, CAST(45.00 AS Decimal(5, 2)), N'Juana ha demostrado ser una excelente empleada. Espero que continue asi, mejorando con el tiempo y excelente desempeño.', 7, 1, 1, N'pramirez')
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (6, 7, CAST(N'2025-03-12' AS Date), 6, CAST(45.00 AS Decimal(5, 2)), N'Excelente, muy buen trabajo este periodo!', 8, 1, 1, N'pramirez')
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (7, 7, CAST(N'2025-03-12' AS Date), 6, CAST(45.00 AS Decimal(5, 2)), N'Este año Juana ha demostrado ser una excelente colaboradora, saliendo adelante con su trabajo y tareas. Siga asi!', 9, 1, 1, N'pramirez')
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (8, 7, CAST(N'2025-03-12' AS Date), NULL, NULL, NULL, 4, 0, 0, NULL)
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (10, 5, CAST(N'2025-03-13' AS Date), NULL, NULL, NULL, 2, 0, 0, NULL)
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (11, 7, CAST(N'2025-03-14' AS Date), NULL, NULL, NULL, 3, 0, 0, NULL)
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (12, 7, CAST(N'2025-03-14' AS Date), NULL, NULL, NULL, 2, 0, 0, NULL)
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (13, 1007, CAST(N'2025-03-19' AS Date), 2, CAST(44.00 AS Decimal(5, 2)), N'Ernesto demostró en ese trimestre ser un muy buen empleado y compañero. Se lleva bien con el equipo y se ha adaptado rápidamente.', 8, 1, 1, N'dcuellar')
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (14, 1007, CAST(N'2025-03-19' AS Date), NULL, NULL, NULL, 9, 0, 0, NULL)
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (15, 1007, CAST(N'2025-03-19' AS Date), NULL, NULL, NULL, 1, 0, 0, NULL)
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (16, 1011, CAST(N'2025-03-28' AS Date), NULL, NULL, NULL, 1, 0, 0, NULL)
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (17, 1011, CAST(N'2025-03-28' AS Date), NULL, NULL, NULL, 2, 0, 0, NULL)
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (18, 1011, CAST(N'2025-03-28' AS Date), NULL, NULL, NULL, 3, 0, 0, NULL)
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (19, 1016, CAST(N'2025-03-28' AS Date), NULL, NULL, NULL, 1, 0, 0, NULL)
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (20, 5, CAST(N'2025-04-02' AS Date), NULL, NULL, NULL, 1, 1, 0, NULL)
INSERT [dbo].[Evaluaciones] ([id_evaluacion], [id_empleado], [fecha_evaluacion], [id_supervisor], [resultado_promedio], [comentarios_supervisor], [id_periodo], [finalizada], [EvaluadaSupervisor], [EvaluadoPor]) VALUES (21, 5, CAST(N'2025-04-02' AS Date), NULL, NULL, NULL, 3, 0, 0, NULL)
SET IDENTITY_INSERT [dbo].[Evaluaciones] OFF
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (3, 10, 5, 5, N'Siempre cumplo con mis objetivos.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (3, 11, 5, 5, N'Siempre realizo mis tareas eficientemente.', N'Muy dedicada a sus tareas.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (3, 12, 4, 4, N'busco mejorar mis habilidades capacitandome.', N'De acuerdo, puede mejorar en buscar cursos para su area.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (3, 13, 5, 5, N'Busco siempre seguir las normas de la empresa.', N'De acuerdo, sigue con las normas de la empresa.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (3, 14, 4, 5, N'busco alinear mis valores con la mision y vision de la empresa.', N'Llena las expectativas.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (3, 15, 4, 4, N'Si.', N'Debe trabajar un poquito mas en esta area.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (3, 16, 5, 5, N'Tengo muy buena relación con mis colegas y los respeto.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (3, 17, 5, 5, N'Claro que si.', N'Si cumple.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (3, 18, 5, 5, N'Respeto mucho mi trabajo.', N'Muy de acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (5, 10, 5, 5, N'Siempre cumplo con mis objetivos.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (5, 11, 4, 5, N'Trato de minimizar errores.', N'Ha mejorado notablemente.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (5, 12, 5, 5, N'Siempre busco mejorar.', N'Su trabajo diario ha mejorado.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (5, 13, 5, 5, N'Si cumplo con las normas.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (5, 14, 5, 5, N'Si.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (5, 15, 4, 5, N'Trato de hacerlo con mi trabajo a diario.', N'Cumple con los objetivos establecidos.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (5, 16, 5, 5, N'Tengo buenas relaciones con mis compañeros.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (5, 17, 5, 5, N'Si.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (5, 18, 5, 5, N'Mi posicion requiere mucha confidencialidad por lo que debo actuar con integridad.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (6, 10, 5, 5, N'Este trimestre he cumplido con todas mis metas.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (6, 11, 4, 5, N'Aunque aun hay algunos puntos de mejora, he minimizado errores.', N'Muy de acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (6, 12, 5, 5, N'Siempre busco oporunidad de capacitarme.', N'Ha completado sus capacitaciones asignadas.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (6, 13, 4, 5, N'Trato siempre de cumplir con las normas y políticas de la empresa.', N'Siempre cumple.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (6, 14, 4, 5, N'Si.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (6, 15, 3, 5, N'Si cumplo con los objetivos.', N'De acuerdo')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (6, 16, 5, 5, N'Siempre muestro respeto hacia mis compañeros.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (6, 17, 5, 5, N'Si cumplo con todas las regulaciones.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (6, 18, 5, 5, N'Siempre actúo con integridad en mis labores diarias.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (7, 10, 5, 5, N'Si cumplo.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (7, 11, 5, 5, N'He mejorado utilizando las herramientas.', N'Notablemente, especialmente con excel.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (7, 12, 4, 5, N'He tenido un poco de dificultad pero he mejorado.', N'Ha presentado mejoría.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (7, 13, 5, 5, N'Si cumplo.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (7, 14, 5, 5, N'Trato de hacerlo a diario.', N'Siempre lo demuestra.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (7, 15, 5, 5, N'Siempre busco contribuir con los objetivos.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (7, 16, 5, 5, N'Siempre.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (7, 17, 5, 5, N'Si.', N'Si cumple con las regulaciones y politicas de etica.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (7, 18, 5, 5, N'Mi puesto es confidencial y debo actuar con integridad.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (13, 10, 4, 5, N'En mis labores busco cumplir con los objetivos.', N'Muy dedicado.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (13, 11, 5, 5, N'Trato de minimizar los errores lo mas posible realizando mi trabajo cuidadosamente.', N'Si, bastante eficiente. Siga asi.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (13, 12, 4, 4, N'Intento cursar las capacitaciones asignadas en el tiempo establecido.', N'Necesita completar las capacitaciones asignadas.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (13, 13, 5, 5, N'Si.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (13, 14, 5, 5, N'Aplico estos valores en mi trabajo.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (13, 15, 5, 5, N'Si siempre contribuyo a estos objetivos.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (13, 16, 5, 5, N'Con mis compañeros tenemos buena relacion.', N'Muy respetuoso y servicial.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (13, 17, 5, 5, N'Si.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (13, 18, 5, 5, N'Debo hacerlo para poder realizar bien mi trabajo.', N'De acuerdo.')
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (20, 1, 5, 0, N'asdf', NULL)
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (20, 2, 4, 0, N'asdf', NULL)
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (20, 3, 5, 0, N'asdf', NULL)
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (20, 4, 5, 0, N'sdfg', NULL)
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (20, 5, 4, 0, N'asdf', NULL)
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (20, 6, 4, 0, N'sdfg', NULL)
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (20, 7, 5, 0, N'fdgh', NULL)
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (20, 8, 5, 0, N'sdfg', NULL)
INSERT [dbo].[EvaluacionesPreguntas] ([id_evaluacion], [id_pregunta], [puntaje_empleado], [puntaje_supervisor], [comentario_empleado], [comentario_supervisor]) VALUES (20, 9, 4, 0, N'aSD', NULL)
SET IDENTITY_INSERT [dbo].[Mensajes] ON 

INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (1, 6, 11, N'Hola Juana, ya envio el reporte?', CAST(N'2025-03-02 01:33:46.167' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (2, 6, 9, N'hola Juan, puedes enviarme el permiso.', CAST(N'2025-03-02 21:13:00.703' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (3, 9, 6, N'claro, ya lo enviare.', CAST(N'2025-03-02 21:13:55.820' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (4, 6, 9, N'lo enviaste?', CAST(N'2025-03-02 21:16:41.930' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (5, 6, 9, N'hola?', CAST(N'2025-03-02 22:18:13.730' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (6, 6, 9, N'hola?', CAST(N'2025-03-03 21:53:20.510' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (7, 9, 6, N'hola David', CAST(N'2025-03-03 22:44:25.413' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (8, 9, 6, N'hola?', CAST(N'2025-03-03 23:35:26.757' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (9, 6, 9, N'hola Juan', CAST(N'2025-03-03 23:36:06.197' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (10, 10, 6, N'David me puede ayudar enviandome el reporte porfa?', CAST(N'2025-03-03 23:37:08.780' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (11, 6, 10, N'ya se lo enviare paola.', CAST(N'2025-03-04 00:31:57.463' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (12, 10, 6, N'esta bien.', CAST(N'2025-03-04 01:04:15.297' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (13, 6, 9, N'hola??', CAST(N'2025-03-04 01:39:13.067' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (14, 6, 9, N'hola Juan, estas disponible?', CAST(N'2025-03-04 12:37:16.500' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (15, 9, 6, N'Si David, que necesitas?', CAST(N'2025-03-04 12:37:51.137' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (16, 6, 9, N'Necesito que me envies la justificacion del dia que no estuviste.', CAST(N'2025-03-04 12:40:30.867' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (17, 9, 6, N'Ok te lo enviare', CAST(N'2025-03-04 12:41:34.457' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (18, 9, 6, N'ahora te lo enviare.', CAST(N'2025-03-04 12:43:00.377' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (19, 6, 9, N'ok.', CAST(N'2025-03-04 12:43:32.767' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (20, 6, 10, N'Paola no tengo el documento aun.', CAST(N'2025-03-04 13:20:39.613' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (21, 10, 6, N'lo necesita para ya?', CAST(N'2025-03-04 13:24:03.963' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (22, 10, 6, N'se lo podriamos enviar luego', CAST(N'2025-03-04 13:25:06.260' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (23, 6, 10, N'si mejor enviemelo despues', CAST(N'2025-03-04 13:25:39.550' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (24, 10, 6, N'esta bien, por la tarde lo envio.', CAST(N'2025-03-04 13:27:15.430' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (25, 6, 10, N'muy bien Paola, quedo pendiente.', CAST(N'2025-03-04 13:32:44.630' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (26, 10, 6, N'gracias David.', CAST(N'2025-03-04 13:39:12.837' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (27, 6, 10, N'a usted.', CAST(N'2025-03-04 14:08:14.150' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (28, 10, 6, N'ok listo ya se lo envie.', CAST(N'2025-03-04 14:44:05.327' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (29, 6, 10, N'gracias', CAST(N'2025-03-04 14:44:32.450' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (30, 6, 10, N'no me lo ha enviado.', CAST(N'2025-03-04 15:03:51.273' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (31, 10, 6, N'disculpe ahora mismo lo enviare.', CAST(N'2025-03-04 15:04:32.467' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (32, 6, 10, N'gracias', CAST(N'2025-03-04 15:17:19.657' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (33, 10, 6, N'a usted.', CAST(N'2025-03-04 15:25:45.220' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (34, 6, 9, N'hola', CAST(N'2025-03-04 16:03:40.050' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (35, 6, 9, N'juan, sigues ahi?', CAST(N'2025-03-04 16:09:20.770' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (36, 9, 6, N'Aca sigo, estimado.', CAST(N'2025-03-04 16:18:56.290' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (37, 6, 9, N'asdfasdfasdfasdfasdfasdfasdfasdfasdfafasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf', CAST(N'2025-03-05 15:17:50.310' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (38, 6, 9, N'asdfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffasdfasdfasdfasdfasdf', CAST(N'2025-03-05 15:18:05.613' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (39, 9, 6, N'que es eso?', CAST(N'2025-03-05 15:56:48.423' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (40, 11, 6, N'Hola, ahora lo enviare.', CAST(N'2025-03-05 15:57:13.970' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (41, 10, 6, N'lo reviso?', CAST(N'2025-03-05 15:58:00.617' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (42, 9, 6, N'hola, estas?', CAST(N'2025-03-05 21:24:35.573' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (43, 9, 6, N'hola?', CAST(N'2025-03-15 17:49:19.100' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (44, 9, 6, N'?', CAST(N'2025-03-15 18:06:42.333' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (45, 6, 1011, N'hola ernesto falta ingresar justificacion de su permiso', CAST(N'2025-03-15 19:17:32.063' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (46, 1011, 6, N'ya fue ingresado al igual que la autoevaluacion.', CAST(N'2025-03-19 23:10:48.067' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (47, 6, 1011, N'gracias', CAST(N'2025-03-19 23:17:46.547' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (48, 6, 1011, N'Hola?', CAST(N'2025-03-20 00:05:27.240' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (49, 10, 1011, N'Esta disponible?', CAST(N'2025-03-20 00:05:56.293' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (50, 1012, 1011, N'Hola?', CAST(N'2025-03-20 00:06:38.593' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (51, 6, 1011, N'??', CAST(N'2025-03-20 00:29:44.990' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (52, 1015, 10, N'hola?', CAST(N'2025-03-28 16:23:15.987' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (53, 1011, 6, N'hola estimado, ya ingrese las vacaciones que deseo tomar en octubre.', CAST(N'2025-03-28 19:26:14.700' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (54, 6, 1011, N'aprobadas.', CAST(N'2025-03-28 19:27:46.597' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (55, 1020, 1019, N'Hi', CAST(N'2025-03-28 22:22:49.580' AS DateTime), 0)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (56, 9, 6, N'HOLA!', CAST(N'2025-04-02 23:13:30.397' AS DateTime), 1)
INSERT [dbo].[Mensajes] ([id_mensaje], [id_emisor], [id_receptor], [mensaje], [fecha_envio], [leido]) VALUES (57, 6, 9, N'HOLA!', CAST(N'2025-04-02 23:14:03.617' AS DateTime), 0)
SET IDENTITY_INSERT [dbo].[Mensajes] OFF
SET IDENTITY_INSERT [dbo].[Notificaciones] ON 

INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1, 5, N'Permiso Rechazado', CAST(N'2025-03-15 15:24:04.823' AS DateTime), 1, N'Permiso')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (2, 5, N'Permiso Aprobado', CAST(N'2025-03-15 17:11:34.027' AS DateTime), 1, N'Permiso')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (3, 5, N'Permiso Rechazado', CAST(N'2025-03-15 17:29:44.863' AS DateTime), 1, N'Permiso')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (4, 1007, N'Permiso Aprobado', CAST(N'2025-03-15 19:18:32.043' AS DateTime), 1, N'Permiso')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (5, 6, N'Nuevo permiso solicitado por un empleado', CAST(N'2025-03-18 00:22:54.583' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (7, 2, N'Nuevo permiso solicitado por un empleado', CAST(N'2025-03-18 00:39:29.963' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (8, 1007, N'Permiso Aprobado', CAST(N'2025-03-18 00:43:07.620' AS DateTime), 1, N'Permiso')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (9, 1008, N'Nuevo permiso solicitado por Juan Perez', CAST(N'2025-03-18 01:00:49.603' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1005, 2, N'Nuevo permiso solicitado por Ernesto Martinez', CAST(N'2025-03-18 23:02:55.133' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1006, 1007, N'Permiso Rechazado', CAST(N'2025-03-18 23:07:56.480' AS DateTime), 1, N'Permiso')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1007, 1007, N'Permiso Aprobado', CAST(N'2025-03-18 23:13:20.230' AS DateTime), 1, N'Permiso')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1008, 5, N'Permiso Aprobado', CAST(N'2025-03-18 23:24:26.793' AS DateTime), 1, N'PermisoAprobado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1009, 2, N'Empleado emartinez ha completado una autoevaluación.', CAST(N'2025-03-19 01:43:08.470' AS DateTime), 1, N'AutoevaluacionCompleta')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1010, 1007, N'Has sido evaluado por David Cuellar.', CAST(N'2025-03-19 02:01:43.137' AS DateTime), 1, N'EvaluacionCompleta')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1011, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-23 19:29:40.083' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1012, 7, N'Permiso Aprobado', CAST(N'2025-03-23 19:30:24.463' AS DateTime), 1, N'PermisoAprobado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1013, 2, N'Nuevo permiso solicitado por Ernesto Martinez', CAST(N'2025-03-25 20:11:32.333' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1014, 2, N'Nuevo permiso solicitado por Ernesto Martinez', CAST(N'2025-03-25 20:18:26.787' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1015, 1007, N'Permiso Aprobado', CAST(N'2025-03-25 20:19:22.733' AS DateTime), 1, N'PermisoAprobado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1016, 2, N'Nuevo permiso solicitado por Ernesto Martinez', CAST(N'2025-03-25 23:49:19.297' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1017, 1007, N'Permiso Rechazado', CAST(N'2025-03-25 23:58:42.407' AS DateTime), 1, N'PermisoRechazado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1018, 2, N'Nuevo permiso solicitado por Ernesto Martinez', CAST(N'2025-03-25 23:59:22.843' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1019, 7, N'Has sido evaluado por Paola Ramirez.', CAST(N'2025-03-26 00:13:41.063' AS DateTime), 1, N'EvaluacionCompleta')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1020, 7, N'Has sido evaluado por Paola Ramirez.', CAST(N'2025-03-26 00:18:33.370' AS DateTime), 1, N'EvaluacionCompleta')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1021, 6, N'Juana Perez ha completado una autoevaluación.', CAST(N'2025-03-26 00:44:04.983' AS DateTime), 1, N'AutoevaluacionCompleta')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1022, 7, N'Has sido evaluado por Paola Ramirez.', CAST(N'2025-03-26 00:48:31.133' AS DateTime), 1, N'EvaluacionCompleta')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1023, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-26 00:50:45.677' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1024, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-27 12:36:56.203' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1025, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-27 12:40:28.803' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1026, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-27 12:41:40.887' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1027, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-27 13:33:51.957' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1028, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-27 13:34:17.057' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1029, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-27 14:11:07.997' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1030, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-27 14:12:53.027' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1031, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-27 14:58:22.363' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1032, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-27 14:59:09.577' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1033, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-27 15:14:51.520' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1034, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-27 15:16:22.733' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1035, 6, N'Nuevo permiso solicitado por Juana Perez', CAST(N'2025-03-27 15:17:16.990' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1036, 2, N'Nuevo permiso solicitado por Ernesto Martinez', CAST(N'2025-03-28 19:23:08.723' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1037, 2, N'Nuevo permiso solicitado por Ernesto Martinez', CAST(N'2025-03-28 19:25:16.290' AS DateTime), 1, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1038, 1007, N'Permiso Aprobado', CAST(N'2025-03-28 19:27:17.900' AS DateTime), 1, N'PermisoAprobado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1039, 1007, N'Permiso Aprobado', CAST(N'2025-03-28 19:27:37.547' AS DateTime), 1, N'PermisoAprobado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1040, 1010, N'Nuevo permiso solicitado por Esmeralda Pinto', CAST(N'2025-03-28 22:21:23.440' AS DateTime), 0, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1041, 1016, N'Permiso Aprobado', CAST(N'2025-03-28 22:25:50.610' AS DateTime), 1, N'PermisoAprobado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1042, 1008, N'Nuevo permiso solicitado por Juan Perez', CAST(N'2025-04-02 00:24:43.417' AS DateTime), 0, N'PermisoSolicitado')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1043, 5, N'Has sido evaluado por Paola Ramirez.', CAST(N'2025-04-02 17:29:30.767' AS DateTime), 0, N'EvaluacionCompleta')
INSERT [dbo].[Notificaciones] ([id_notificacion], [id_empleado], [mensaje], [fecha_creacion], [leido], [tipo]) VALUES (1044, 1008, N'Juan Perez ha completado una autoevaluación.', CAST(N'2025-04-02 17:44:33.233' AS DateTime), 0, N'AutoevaluacionCompleta')
SET IDENTITY_INSERT [dbo].[Notificaciones] OFF
SET IDENTITY_INSERT [dbo].[PeriodosEvaluacion] ON 

INSERT [dbo].[PeriodosEvaluacion] ([id_periodo], [anio], [trimestre], [fecha_inicio], [fecha_fin]) VALUES (1, 2025, 1, CAST(N'2025-01-01' AS Date), CAST(N'2025-03-31' AS Date))
INSERT [dbo].[PeriodosEvaluacion] ([id_periodo], [anio], [trimestre], [fecha_inicio], [fecha_fin]) VALUES (2, 2025, 2, CAST(N'2025-04-01' AS Date), CAST(N'2025-06-30' AS Date))
INSERT [dbo].[PeriodosEvaluacion] ([id_periodo], [anio], [trimestre], [fecha_inicio], [fecha_fin]) VALUES (3, 2025, 3, CAST(N'2025-07-01' AS Date), CAST(N'2025-09-30' AS Date))
INSERT [dbo].[PeriodosEvaluacion] ([id_periodo], [anio], [trimestre], [fecha_inicio], [fecha_fin]) VALUES (4, 2025, 4, CAST(N'2025-10-01' AS Date), CAST(N'2025-12-31' AS Date))
INSERT [dbo].[PeriodosEvaluacion] ([id_periodo], [anio], [trimestre], [fecha_inicio], [fecha_fin]) VALUES (6, 2024, 1, CAST(N'2024-01-01' AS Date), CAST(N'2024-03-31' AS Date))
INSERT [dbo].[PeriodosEvaluacion] ([id_periodo], [anio], [trimestre], [fecha_inicio], [fecha_fin]) VALUES (7, 2024, 2, CAST(N'2024-04-01' AS Date), CAST(N'2024-06-30' AS Date))
INSERT [dbo].[PeriodosEvaluacion] ([id_periodo], [anio], [trimestre], [fecha_inicio], [fecha_fin]) VALUES (8, 2024, 3, CAST(N'2024-07-01' AS Date), CAST(N'2024-09-30' AS Date))
INSERT [dbo].[PeriodosEvaluacion] ([id_periodo], [anio], [trimestre], [fecha_inicio], [fecha_fin]) VALUES (9, 2024, 4, CAST(N'2024-10-01' AS Date), CAST(N'2024-12-31' AS Date))
SET IDENTITY_INSERT [dbo].[PeriodosEvaluacion] OFF
SET IDENTITY_INSERT [dbo].[Permisos] ON 

INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (1, 5, 1, CAST(N'2025-02-26' AS Date), CAST(N'2025-02-28' AS Date), N'aprobado', N'', NULL, NULL, CAST(N'2025-02-27 19:48:26.863' AS DateTime), 24, NULL, NULL, 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (2, 5, 1, CAST(N'2025-02-20' AS Date), CAST(N'2025-02-20' AS Date), N'rechazado', N'', N'', N'C:\Users\dcuel\Desktop\CEUTEC\2024_2025 PROYECTO GRADUACION\Sistema_RRHH\Permisos\20250227204822_constanciaMedica.png', CAST(N'2025-02-27 20:48:22.717' AS DateTime), 8, N'pramirez', CAST(N'2025-02-28 23:35:18.910' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (3, 5, 1, CAST(N'2025-03-03' AS Date), CAST(N'2025-03-03' AS Date), N'rechazado', N'', N'', NULL, CAST(N'2025-02-27 22:06:44.297' AS DateTime), 8, N'pramirez', CAST(N'2025-02-28 23:35:17.967' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (4, 5, 1, CAST(N'2025-03-07' AS Date), CAST(N'2025-03-07' AS Date), N'rechazado', N'de 8 a 11am', N'', NULL, CAST(N'2025-02-27 22:40:36.147' AS DateTime), 3, N'pramirez', CAST(N'2025-02-28 23:35:17.030' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (5, 5, 1, CAST(N'2025-03-12' AS Date), CAST(N'2025-03-12' AS Date), N'rechazado', N'de 8 a 11am', N'', NULL, CAST(N'2025-02-27 22:43:37.493' AS DateTime), 3, N'pramirez', CAST(N'2025-02-28 23:35:15.940' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (6, 7, 1, CAST(N'2025-02-27' AS Date), CAST(N'2025-02-28' AS Date), N'aprobado', N'', N'', NULL, CAST(N'2025-02-28 00:05:03.103' AS DateTime), 16, NULL, NULL, 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (7, 2, 1, CAST(N'2025-03-07' AS Date), CAST(N'2025-03-10' AS Date), N'rechazado', N'', N'Debe asistir a ambas reuniones, viernes y lunes. Favor presentarse.', NULL, CAST(N'2025-02-28 17:29:09.600' AS DateTime), 16, NULL, NULL, 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (8, 5, 1, CAST(N'2025-03-14' AS Date), CAST(N'2025-03-14' AS Date), N'aprobado', N'', N'Que disfrute.', NULL, CAST(N'2025-02-28 23:52:42.227' AS DateTime), 8, N'pramirez', CAST(N'2025-03-01 01:55:07.697' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (1008, 5, 1, CAST(N'2025-03-24' AS Date), CAST(N'2025-03-24' AS Date), N'rechazado', N'Atender asunto personal.', N'paselo para el viernes.', NULL, CAST(N'2025-03-15 15:23:02.333' AS DateTime), 8, N'pramirez', CAST(N'2025-03-15 15:24:04.807' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (1009, 5, 1, CAST(N'2025-03-24' AS Date), CAST(N'2025-03-24' AS Date), N'aprobado', N'Atender asuntos personales.', N'prueba.', NULL, CAST(N'2025-03-15 17:10:40.660' AS DateTime), 8, N'pramirez', CAST(N'2025-03-15 17:11:34.000' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (1010, 5, 1, CAST(N'2025-03-21' AS Date), CAST(N'2025-03-21' AS Date), N'rechazado', N'probando.', N'prueba rechazada.', NULL, CAST(N'2025-03-15 17:29:00.687' AS DateTime), 8, N'pramirez', CAST(N'2025-03-15 17:29:44.840' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (1011, 1007, 1, CAST(N'2025-03-17' AS Date), CAST(N'2025-03-17' AS Date), N'aprobado', N'prueba1', N'disfrute su dia libre.', NULL, CAST(N'2025-03-15 18:47:01.993' AS DateTime), 8, N'dcuellar', CAST(N'2025-03-15 19:18:32.020' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (1012, 1007, 1, CAST(N'2025-03-28' AS Date), CAST(N'2025-03-28' AS Date), N'aprobado', N'atender asunto personal.', N'ok, aprobado.', NULL, CAST(N'2025-03-18 00:22:54.550' AS DateTime), 8, N'dcuellar', CAST(N'2025-03-18 23:13:20.223' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (1013, 1007, 1, CAST(N'2025-03-27' AS Date), CAST(N'2025-03-27' AS Date), N'aprobado', N'atender asunto personal.', N'prueba2', NULL, CAST(N'2025-03-18 00:39:29.943' AS DateTime), 8, N'dcuellar', CAST(N'2025-03-18 00:43:07.590' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (1014, 5, 1, CAST(N'2025-03-26' AS Date), CAST(N'2025-03-26' AS Date), N'aprobado', N'pruebaaa', N'Listo, aprobado.', NULL, CAST(N'2025-03-18 01:00:49.573' AS DateTime), 8, N'pperez', CAST(N'2025-03-18 23:24:26.773' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (2012, 1007, 1, CAST(N'2025-03-26' AS Date), CAST(N'2025-03-26' AS Date), N'rechazado', N'Prueba.', N'Termine lo pendiente.', NULL, CAST(N'2025-03-18 23:02:55.100' AS DateTime), 8, N'dcuellar', CAST(N'2025-03-18 23:07:56.470' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (2013, 7, 1, CAST(N'2024-11-25' AS Date), CAST(N'2024-11-27' AS Date), N'aprobado', N'Vacaciones.', N'días pendientes de ingresas. gracias.', NULL, CAST(N'2025-03-23 19:29:40.067' AS DateTime), 24, N'pramirez', CAST(N'2025-03-23 19:30:24.450' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (2016, 1007, 1, CAST(N'2025-03-31' AS Date), CAST(N'2025-03-31' AS Date), N'rechazado', N'', N'vuelva a ingresar.', NULL, CAST(N'2025-03-25 23:49:19.277' AS DateTime), 8, N'dcuellar', CAST(N'2025-03-25 23:58:42.390' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (2017, 1007, 1, CAST(N'2025-04-04' AS Date), CAST(N'2025-04-04' AS Date), N'aprobado', N'', N'listo.', NULL, CAST(N'2025-03-25 23:59:22.817' AS DateTime), 8, N'dcuellar', CAST(N'2025-03-28 19:27:37.530' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (2032, 1007, 1, CAST(N'2025-10-01' AS Date), CAST(N'2025-10-06' AS Date), N'aprobado', N'vacaciones por viaje.', N'listo que disfrute.', NULL, CAST(N'2025-03-28 19:25:16.270' AS DateTime), 24, N'dcuellar', CAST(N'2025-03-28 19:27:17.877' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (2033, 1016, 1, CAST(N'2025-04-11' AS Date), CAST(N'2025-04-18' AS Date), N'aprobado', N'Vacaciones por semana santa 2025', N'aprobado', NULL, CAST(N'2025-03-28 22:21:23.403' AS DateTime), 24, N'pramirez', CAST(N'2025-03-28 22:25:50.577' AS DateTime), 0)
INSERT [dbo].[Permisos] ([id_permiso], [id_empleado], [id_tipo_permiso], [fecha_inicio], [fecha_fin], [estado], [comentarios_empleado], [comentarios_supervisor], [documento], [fecha_solicitud], [horas_solicitadas], [revisado_por], [fecha_revisado], [dias_AutoAprobados]) VALUES (2034, 5, 1, CAST(N'2025-04-16' AS Date), CAST(N'2025-04-16' AS Date), N'pendiente', N'Por motivo de viaje.', NULL, NULL, CAST(N'2025-04-02 00:24:43.357' AS DateTime), 8, NULL, NULL, 0)
SET IDENTITY_INSERT [dbo].[Permisos] OFF
SET IDENTITY_INSERT [dbo].[Preguntas] ON 

INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (1, N'¿Cumplo regularmente con las metas y objetivos establecidos para mí posición?', N'Desempeño Laboral')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (2, N'¿Realizo mis tareas con eficiencia y calidad, minimizando errores?', N'Desempeño Laboral')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (3, N'¿Busco constantemente mejorar mis habilidades relacionadas con mi trabajo?', N'Desempeño Laboral')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (4, N'¿Cumplo con las normas y políticas de la empresa de manera consistente?', N'Política Organizacional')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (5, N'¿Muestro alineación con los valores y misión de la organización en mi trabajo diario?', N'Política Organizacional')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (6, N'¿Contribuyo al logro de los objetivos estratégicos de la empresa?', N'Política Organizacional')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (7, N'¿Muestro respeto y empatía hacia mis compañeros de trabajo en todas las interacciones?', N'Cumplimiento')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (8, N'¿Cumplo con las regulaciones y políticas de ética empresarial?', N'Cumplimiento')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (9, N'¿Actúo con integridad en todas las actividades relacionadas con mi posición?', N'Cumplimiento')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (10, N'¿Cumplo regularmente con las metas y objetivos establecidos para mí posición?', N'Desempeño Laboral')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (11, N'¿Realizo mis tareas con eficiencia y calidad, minimizando errores?', N'Desempeño Laboral')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (12, N'¿Busco constantemente mejorar mis habilidades relacionadas con mi trabajo?', N'Desempeño Laboral')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (13, N'¿Cumplo con las normas y políticas de la empresa de manera consistente?', N'Política Organizacional')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (14, N'¿Muestro alineación con los valores y misión de la organización en mi trabajo diario?', N'Política Organizacional')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (15, N'¿Contribuyo al logro de los objetivos estratégicos de la empresa?', N'Política Organizacional')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (16, N'¿Muestro respeto y empatía hacia mis compañeros de trabajo en todas las interacciones?', N'Cumplimiento')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (17, N'¿Cumplo con las regulaciones y políticas de ética empresarial?', N'Cumplimiento')
INSERT [dbo].[Preguntas] ([id_pregunta], [texto_pregunta], [seccion]) VALUES (18, N'¿Actúo con integridad en todas las actividades relacionadas con mi posición?', N'Cumplimiento')
SET IDENTITY_INSERT [dbo].[Preguntas] OFF
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (1, 1)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (1, 2)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (2, 1)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (2, 2)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (3, 1)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (3, 2)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (4, 1)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (4, 2)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (5, 1)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (5, 2)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (6, 1)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (6, 2)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (7, 1)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (7, 2)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (8, 1)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (8, 2)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (9, 1)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (9, 2)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (10, 6)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (10, 7)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (10, 8)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (10, 9)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (11, 6)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (11, 7)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (11, 8)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (11, 9)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (12, 6)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (12, 7)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (12, 8)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (12, 9)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (13, 6)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (13, 7)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (13, 8)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (13, 9)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (14, 6)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (14, 7)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (14, 8)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (14, 9)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (15, 6)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (15, 7)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (15, 8)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (15, 9)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (16, 6)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (16, 7)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (16, 8)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (16, 9)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (17, 6)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (17, 7)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (17, 8)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (17, 9)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (18, 6)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (18, 7)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (18, 8)
INSERT [dbo].[PreguntasPeriodos] ([id_pregunta], [id_periodo]) VALUES (18, 9)
SET IDENTITY_INSERT [dbo].[PreguntasSeguridad] ON 

INSERT [dbo].[PreguntasSeguridad] ([id_pregunta_seguridad], [pregunta]) VALUES (1, N'¿Cuál es el nombre de mi abuelo?')
INSERT [dbo].[PreguntasSeguridad] ([id_pregunta_seguridad], [pregunta]) VALUES (2, N'¿Cómo se llama mi primera mascota?')
INSERT [dbo].[PreguntasSeguridad] ([id_pregunta_seguridad], [pregunta]) VALUES (3, N'¿A qué escuela fui?')
INSERT [dbo].[PreguntasSeguridad] ([id_pregunta_seguridad], [pregunta]) VALUES (4, N'¿En qué año salí del colegio?')
SET IDENTITY_INSERT [dbo].[PreguntasSeguridad] OFF
SET ANSI_PADDING ON
SET IDENTITY_INSERT [dbo].[SaldoPermisos] ON 

INSERT [dbo].[SaldoPermisos] ([id_saldo], [id_empleado], [id_tipo_permiso], [horas_disponibles]) VALUES (1, 5, 1, CAST(24.00 AS Decimal(10, 2)))
INSERT [dbo].[SaldoPermisos] ([id_saldo], [id_empleado], [id_tipo_permiso], [horas_disponibles]) VALUES (2, 7, 1, CAST(40.00 AS Decimal(10, 2)))
INSERT [dbo].[SaldoPermisos] ([id_saldo], [id_empleado], [id_tipo_permiso], [horas_disponibles]) VALUES (3, 2, 1, CAST(80.00 AS Decimal(10, 2)))
INSERT [dbo].[SaldoPermisos] ([id_saldo], [id_empleado], [id_tipo_permiso], [horas_disponibles]) VALUES (1002, 1007, 1, CAST(32.00 AS Decimal(10, 2)))
INSERT [dbo].[SaldoPermisos] ([id_saldo], [id_empleado], [id_tipo_permiso], [horas_disponibles]) VALUES (1003, 1007, 7, CAST(120.00 AS Decimal(10, 2)))
INSERT [dbo].[SaldoPermisos] ([id_saldo], [id_empleado], [id_tipo_permiso], [horas_disponibles]) VALUES (1004, 7, 8, CAST(40.00 AS Decimal(10, 2)))
INSERT [dbo].[SaldoPermisos] ([id_saldo], [id_empleado], [id_tipo_permiso], [horas_disponibles]) VALUES (1005, 1016, 1, CAST(56.00 AS Decimal(10, 2)))
SET IDENTITY_INSERT [dbo].[SaldoPermisos] OFF
SET ANSI_PADDING OFF
SET ANSI_PADDING ON
SET IDENTITY_INSERT [dbo].[SupervisoresDepartamento] ON 

INSERT [dbo].[SupervisoresDepartamento] ([id_supervisor_depto], [id_empleado], [id_departamento]) VALUES (2, 2, 2)
INSERT [dbo].[SupervisoresDepartamento] ([id_supervisor_depto], [id_empleado], [id_departamento]) VALUES (3, 6, 1)
INSERT [dbo].[SupervisoresDepartamento] ([id_supervisor_depto], [id_empleado], [id_departamento]) VALUES (4, 1008, 4)
INSERT [dbo].[SupervisoresDepartamento] ([id_supervisor_depto], [id_empleado], [id_departamento]) VALUES (5, 1009, 3)
INSERT [dbo].[SupervisoresDepartamento] ([id_supervisor_depto], [id_empleado], [id_departamento]) VALUES (6, 1010, 8)
SET IDENTITY_INSERT [dbo].[SupervisoresDepartamento] OFF
SET ANSI_PADDING OFF
SET ANSI_PADDING ON
SET IDENTITY_INSERT [dbo].[TiposPermisos] ON 

INSERT [dbo].[TiposPermisos] ([id_tipo_permiso], [nombre_permiso], [justificacion], [dias_maximos_anuales], [dias_maximos_mensuales], [requiere_documento]) VALUES (1, N'Vacaciones', N'Código de Trabajo de Honduras, Artículo 346', 10, NULL, 0)
INSERT [dbo].[TiposPermisos] ([id_tipo_permiso], [nombre_permiso], [justificacion], [dias_maximos_anuales], [dias_maximos_mensuales], [requiere_documento]) VALUES (4, N'Maternidad', N'Código de Trabajo de Honduras, Artículo 135 - descanso forzoso, durante las cuatro (4) semanas que precedan al parto y las seis (6) que le sigan', 70, NULL, 1)
INSERT [dbo].[TiposPermisos] ([id_tipo_permiso], [nombre_permiso], [justificacion], [dias_maximos_anuales], [dias_maximos_mensuales], [requiere_documento]) VALUES (5, N'Enfermedad sin Incapacidad', N'Determinado por la empresa. Empleado puede ausentarse sin constancia médica.', 3, NULL, 0)
INSERT [dbo].[TiposPermisos] ([id_tipo_permiso], [nombre_permiso], [justificacion], [dias_maximos_anuales], [dias_maximos_mensuales], [requiere_documento]) VALUES (6, N'Enfermedad con Incapacidad', N'Derecho a ausentarse por enfermedad con incapacidad médica está regulado en los artículos 100 y 104 del Código de Trabajo.', 120, NULL, 1)
INSERT [dbo].[TiposPermisos] ([id_tipo_permiso], [nombre_permiso], [justificacion], [dias_maximos_anuales], [dias_maximos_mensuales], [requiere_documento]) VALUES (7, N'Asunto personal o familiar', N'Licencia determinado por la empresa. Presentar documentación o justificación si es posible.', 15, 2, 1)
INSERT [dbo].[TiposPermisos] ([id_tipo_permiso], [nombre_permiso], [justificacion], [dias_maximos_anuales], [dias_maximos_mensuales], [requiere_documento]) VALUES (8, N'Asueto', N'Determinado por la empresa. Usar solamente con previa autorización por parte de gerencia.', 5, 3, 0)
SET IDENTITY_INSERT [dbo].[TiposPermisos] OFF
SET ANSI_PADDING OFF
SET ANSI_PADDING ON
SET IDENTITY_INSERT [dbo].[Usuarios] ON 

INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (1, N'admin', N'240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', N'admin', N'Activo', NULL, NULL)
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (6, N'dcuellar', N'2f9e00b2753a73089d67ad0351bd2d016823c59ce8e73e27bc9d228ff8bfbbbc', N'supervisor', N'Activo', 2, N'f648ec6d69fb3828b7b3fae3c0504083bcaf919a904c3ad9f410674eff899620')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (9, N'jperez', N'a6525c29ac513f46db7f047c962273b518b0468909adc7b1c58c5b5661ea43de', N'empleado', N'Activo', 2, N'a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (10, N'pramirez', N'7e96a9e995f001a4462e5979ee43c16bc0a3848cc0f232c01cf8d0a8a8652652', N'rh', N'Activo', 2, N'9d77a24d0f4c91a2e968ca607e49dd3b15d5489f66a5bc81fa72803b32443419')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (11, N'juanap', N'd649937aeec1bcd91b291e75d2f20cb8572ef35155caf3bd682cfe6bf259f29b', N'empleado', N'Activo', 2, N'a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (1011, N'emartinez', N'240ad18c901b1f419030071f2e737b957312ab082ca3b134a743cc0d2dcb6c4f', N'empleado', N'Activo', 2, N'a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (1012, N'pperez', N'00767e8185d25da7789acb36c1f0dc06fd8c8ad49bc5c764e65c7e64e1a75415', N'supervisor', N'Activo', 2, N'a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (1013, N'mponce', N'1cfaaebe60124777d1e9bd8744ea9e98a5ce4736470a789322af666e9f19d0fe', N'supervisor', N'Activo', 2, N'a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (1014, N'njimenez', N'2769f6ea2a49744ff6b4ab2b294aa13d71c1761cf5775de262709a4ae2c118a8', N'supervisor', N'Activo', 2, N'9d77a24d0f4c91a2e968ca607e49dd3b15d5489f66a5bc81fa72803b32443419')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (1015, N'mmazier', N'e7be39b0a702945ccc80f678c0b512bc99054c818c3c666b08d24096a39ce090', N'empleado', N'Activo', 2, N'a671e1605a46713ef7fc2d0dab065ddfe20f2415ae9c724cc039129902d885ef')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (1016, N'vpadilla', N'104a41cc37911fdeec9eb9174acbb5aa7b91ef1e89c6adb923f8ff79dd6212c0', N'empleado', N'Activo', 2, N'9d77a24d0f4c91a2e968ca607e49dd3b15d5489f66a5bc81fa72803b32443419')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (1017, N'jardon', N'b4688d2deeeee592c5d6d985ef05852c609fe766927de0181cc5ccc254137d23', N'empleado', N'Activo', 2, N'a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (1018, N'arivera', N'e0b96409b5609c5a1015c3aa05362604317284538d096efdd1f0d25343fe1717', N'empleado', N'Activo', 2, N'9d77a24d0f4c91a2e968ca607e49dd3b15d5489f66a5bc81fa72803b32443419')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (1019, N'dmartinez', N'ff2583c134e394b1b166f8b28c2fa228ac6ab298b83a0912c6a21235ca2f0bf0', N'empleado', N'Activo', 2, N'a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8')
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (1020, N'epinto', N'65c184997f4a765c37447e2fd72cd4ee4cb766445440c93d5a679fcb877528a4', N'empleado', N'Activo', NULL, NULL)
INSERT [dbo].[Usuarios] ([id_usuario], [username], [password], [rol], [Estado], [id_pregunta_seguridad], [respuesta_seguridad]) VALUES (1021, N'tadmin', N'5c0db59995b0935755cca73b34fe1feabd855ca69b3257597f2e5dc1ae98d5be', N'admin', N'Activo', 2, N'a1a5936d3b0f8a69fd62c91ed9990d3bd414c5e78c603e2837c65c9f46a93eb8')
SET IDENTITY_INSERT [dbo].[Usuarios] OFF
SET ANSI_PADDING OFF
SET ANSI_PADDING ON

GO
/****** Object:  Index [UQ__Empleado__2A586E0B02CCDEE0]    Script Date: 4/23/2025 6:34:55 PM ******/
ALTER TABLE [dbo].[Empleados] ADD UNIQUE NONCLUSTERED 
(
	[correo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [UQ__Usuarios__F3DBC572292A114A]    Script Date: 4/23/2025 6:34:55 PM ******/
ALTER TABLE [dbo].[Usuarios] ADD UNIQUE NONCLUSTERED 
(
	[username] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Anuncios] ADD  DEFAULT (getdate()) FOR [fecha_publicacion]
GO
ALTER TABLE [dbo].[Anuncios] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[Auditoria] ADD  DEFAULT (getdate()) FOR [fecha_cambio]
GO
ALTER TABLE [dbo].[Empleados] ADD  DEFAULT ('Interno') FOR [TipoEmpleado]
GO
ALTER TABLE [dbo].[Evaluaciones] ADD  CONSTRAINT [DF_Evaluaciones_Finalizada]  DEFAULT ((0)) FOR [finalizada]
GO
ALTER TABLE [dbo].[Evaluaciones] ADD  CONSTRAINT [DF_Evaluaciones_EvaluadaSupervisor]  DEFAULT ((0)) FOR [EvaluadaSupervisor]
GO
ALTER TABLE [dbo].[Mensajes] ADD  DEFAULT (getdate()) FOR [fecha_envio]
GO
ALTER TABLE [dbo].[Mensajes] ADD  DEFAULT ((0)) FOR [leido]
GO
ALTER TABLE [dbo].[Notificaciones] ADD  DEFAULT (getdate()) FOR [fecha_creacion]
GO
ALTER TABLE [dbo].[Notificaciones] ADD  DEFAULT ((0)) FOR [leido]
GO
ALTER TABLE [dbo].[Notificaciones] ADD  DEFAULT ('General') FOR [tipo]
GO
ALTER TABLE [dbo].[Permisos] ADD  DEFAULT ('pendiente') FOR [estado]
GO
ALTER TABLE [dbo].[Permisos] ADD  DEFAULT (getdate()) FOR [fecha_solicitud]
GO
ALTER TABLE [dbo].[Permisos] ADD  DEFAULT ((0)) FOR [dias_AutoAprobados]
GO
ALTER TABLE [dbo].[SaldoPermisos] ADD  CONSTRAINT [DF_SaldoPermisos_horas_disponibles]  DEFAULT ((0)) FOR [horas_disponibles]
GO
ALTER TABLE [dbo].[Usuarios] ADD  DEFAULT ('Activo') FOR [Estado]
GO
ALTER TABLE [dbo].[Anuncios]  WITH CHECK ADD  CONSTRAINT [FK_Anuncios_Usuarios_Creacion] FOREIGN KEY([id_usuario_creacion])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Anuncios] CHECK CONSTRAINT [FK_Anuncios_Usuarios_Creacion]
GO
ALTER TABLE [dbo].[Anuncios]  WITH CHECK ADD  CONSTRAINT [FK_Anuncios_Usuarios_Modificacion] FOREIGN KEY([id_usuario_modificacion])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Anuncios] CHECK CONSTRAINT [FK_Anuncios_Usuarios_Modificacion]
GO
ALTER TABLE [dbo].[Empleados]  WITH CHECK ADD FOREIGN KEY([id_departamento])
REFERENCES [dbo].[Departamentos] ([id_departamento])
GO
ALTER TABLE [dbo].[Empleados]  WITH CHECK ADD FOREIGN KEY([id_usuario])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Empleados]  WITH CHECK ADD  CONSTRAINT [FK_Empleados_Departamentos] FOREIGN KEY([id_departamento])
REFERENCES [dbo].[Departamentos] ([id_departamento])
GO
ALTER TABLE [dbo].[Empleados] CHECK CONSTRAINT [FK_Empleados_Departamentos]
GO
ALTER TABLE [dbo].[Empleados]  WITH CHECK ADD  CONSTRAINT [FK_Empleados_Usuarios] FOREIGN KEY([id_usuario])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Empleados] CHECK CONSTRAINT [FK_Empleados_Usuarios]
GO
ALTER TABLE [dbo].[Evaluaciones]  WITH CHECK ADD FOREIGN KEY([id_empleado])
REFERENCES [dbo].[Empleados] ([id_empleado])
GO
ALTER TABLE [dbo].[Evaluaciones]  WITH CHECK ADD FOREIGN KEY([id_empleado])
REFERENCES [dbo].[Empleados] ([id_empleado])
GO
ALTER TABLE [dbo].[Evaluaciones]  WITH CHECK ADD FOREIGN KEY([id_supervisor])
REFERENCES [dbo].[Empleados] ([id_empleado])
GO
ALTER TABLE [dbo].[Evaluaciones]  WITH CHECK ADD FOREIGN KEY([id_supervisor])
REFERENCES [dbo].[Empleados] ([id_empleado])
GO
ALTER TABLE [dbo].[Evaluaciones]  WITH CHECK ADD  CONSTRAINT [FK_Evaluaciones_Periodos] FOREIGN KEY([id_periodo])
REFERENCES [dbo].[PeriodosEvaluacion] ([id_periodo])
GO
ALTER TABLE [dbo].[Evaluaciones] CHECK CONSTRAINT [FK_Evaluaciones_Periodos]
GO
ALTER TABLE [dbo].[Evaluaciones]  WITH CHECK ADD  CONSTRAINT [FK_Evaluaciones_PeriodosEvaluacion] FOREIGN KEY([id_periodo])
REFERENCES [dbo].[PeriodosEvaluacion] ([id_periodo])
GO
ALTER TABLE [dbo].[Evaluaciones] CHECK CONSTRAINT [FK_Evaluaciones_PeriodosEvaluacion]
GO
ALTER TABLE [dbo].[EvaluacionesPreguntas]  WITH CHECK ADD FOREIGN KEY([id_evaluacion])
REFERENCES [dbo].[Evaluaciones] ([id_evaluacion])
GO
ALTER TABLE [dbo].[EvaluacionesPreguntas]  WITH CHECK ADD FOREIGN KEY([id_evaluacion])
REFERENCES [dbo].[Evaluaciones] ([id_evaluacion])
GO
ALTER TABLE [dbo].[EvaluacionesPreguntas]  WITH CHECK ADD FOREIGN KEY([id_pregunta])
REFERENCES [dbo].[Preguntas] ([id_pregunta])
GO
ALTER TABLE [dbo].[EvaluacionesPreguntas]  WITH CHECK ADD FOREIGN KEY([id_pregunta])
REFERENCES [dbo].[Preguntas] ([id_pregunta])
GO
ALTER TABLE [dbo].[Mensajes]  WITH CHECK ADD  CONSTRAINT [FK_Mensajes_Emisor] FOREIGN KEY([id_emisor])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Mensajes] CHECK CONSTRAINT [FK_Mensajes_Emisor]
GO
ALTER TABLE [dbo].[Mensajes]  WITH CHECK ADD  CONSTRAINT [FK_Mensajes_Receptor] FOREIGN KEY([id_receptor])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Mensajes] CHECK CONSTRAINT [FK_Mensajes_Receptor]
GO
ALTER TABLE [dbo].[Notificaciones]  WITH CHECK ADD  CONSTRAINT [FK_Notificaciones_Empleados] FOREIGN KEY([id_empleado])
REFERENCES [dbo].[Empleados] ([id_empleado])
GO
ALTER TABLE [dbo].[Notificaciones] CHECK CONSTRAINT [FK_Notificaciones_Empleados]
GO
ALTER TABLE [dbo].[Permisos]  WITH CHECK ADD FOREIGN KEY([id_empleado])
REFERENCES [dbo].[Empleados] ([id_empleado])
GO
ALTER TABLE [dbo].[Permisos]  WITH CHECK ADD FOREIGN KEY([id_empleado])
REFERENCES [dbo].[Empleados] ([id_empleado])
GO
ALTER TABLE [dbo].[Permisos]  WITH CHECK ADD FOREIGN KEY([id_tipo_permiso])
REFERENCES [dbo].[TiposPermisos] ([id_tipo_permiso])
GO
ALTER TABLE [dbo].[Permisos]  WITH CHECK ADD FOREIGN KEY([id_tipo_permiso])
REFERENCES [dbo].[TiposPermisos] ([id_tipo_permiso])
GO
ALTER TABLE [dbo].[PreguntasPeriodos]  WITH CHECK ADD FOREIGN KEY([id_periodo])
REFERENCES [dbo].[PeriodosEvaluacion] ([id_periodo])
GO
ALTER TABLE [dbo].[PreguntasPeriodos]  WITH CHECK ADD FOREIGN KEY([id_pregunta])
REFERENCES [dbo].[Preguntas] ([id_pregunta])
GO
ALTER TABLE [dbo].[SaldoPermisos]  WITH CHECK ADD FOREIGN KEY([id_empleado])
REFERENCES [dbo].[Empleados] ([id_empleado])
GO
ALTER TABLE [dbo].[SaldoPermisos]  WITH CHECK ADD FOREIGN KEY([id_tipo_permiso])
REFERENCES [dbo].[TiposPermisos] ([id_tipo_permiso])
GO
ALTER TABLE [dbo].[SupervisoresDepartamento]  WITH CHECK ADD  CONSTRAINT [FK_SupervisoresDepartamento] FOREIGN KEY([id_departamento])
REFERENCES [dbo].[Departamentos] ([id_departamento])
GO
ALTER TABLE [dbo].[SupervisoresDepartamento] CHECK CONSTRAINT [FK_SupervisoresDepartamento]
GO
ALTER TABLE [dbo].[SupervisoresDepartamento]  WITH CHECK ADD  CONSTRAINT [FK_SupervisoresEmpleado] FOREIGN KEY([id_empleado])
REFERENCES [dbo].[Empleados] ([id_empleado])
GO
ALTER TABLE [dbo].[SupervisoresDepartamento] CHECK CONSTRAINT [FK_SupervisoresEmpleado]
GO
ALTER TABLE [dbo].[Usuarios]  WITH CHECK ADD  CONSTRAINT [FK_Usuarios_PreguntasSeguridad] FOREIGN KEY([id_pregunta_seguridad])
REFERENCES [dbo].[PreguntasSeguridad] ([id_pregunta_seguridad])
GO
ALTER TABLE [dbo].[Usuarios] CHECK CONSTRAINT [FK_Usuarios_PreguntasSeguridad]
GO
ALTER TABLE [dbo].[Empleados]  WITH CHECK ADD  CONSTRAINT [CHK_Apellido_Interno] CHECK  (([TipoEmpleado]='Interno' AND [apellido] IS NOT NULL OR [TipoEmpleado]='Externo' AND [apellido] IS NULL))
GO
ALTER TABLE [dbo].[Empleados] CHECK CONSTRAINT [CHK_Apellido_Interno]
GO
/****** Object:  Trigger [dbo].[AuditoriaAnunciosDelete]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaAnunciosDelete]
ON [dbo].[Anuncios]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Anuncios',
        d.id_anuncio,
        'DELETE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM DELETED d;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaAnunciosInsert]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaAnunciosInsert]
ON [dbo].[Anuncios]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Anuncios',
        i.id_anuncio,
        'INSERT',
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaAnunciosUpdate]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaAnunciosUpdate]
ON [dbo].[Anuncios]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Anuncios',
        i.id_anuncio,
        'UPDATE',
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaDepartamentosDelete]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaDepartamentosDelete]
ON [dbo].[Departamentos]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, fecha_cambio, usuario_modificador)
    SELECT 
        'Departamentos',
        d.id_departamento,
        'DELETE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM DELETED d;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaDepartamentosInsert]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaDepartamentosInsert]
ON [dbo].[Departamentos]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Departamentos',
        i.id_departamento,
        'INSERT',
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i;
END;

GO
/****** Object:  Trigger [dbo].[AuditoriaDepartamentosUpdate]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaDepartamentosUpdate]
ON [dbo].[Departamentos]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Departamentos',
        i.id_departamento,
        'UPDATE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i
    INNER JOIN DELETED d ON i.id_departamento = d.id_departamento;
END;

GO
/****** Object:  Trigger [dbo].[AuditoriaEmpleadosDelete]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaEmpleadosDelete]
ON [dbo].[Empleados]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, fecha_cambio, usuario_modificador)
    SELECT 
        'Empleados',
        d.id_empleado,
        'DELETE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM DELETED d;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaEmpleadosInsert]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaEmpleadosInsert]
ON [dbo].[Empleados]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Empleados',
        i.id_empleado,
        'INSERT',
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i;
END;

GO
/****** Object:  Trigger [dbo].[AuditoriaEmpleadosUpdate]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaEmpleadosUpdate]
ON [dbo].[Empleados]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Empleados',
        i.id_empleado,
        'UPDATE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i
    INNER JOIN DELETED d ON i.id_empleado = d.id_empleado;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaMensajesDelete]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaMensajesDelete]
ON [dbo].[Mensajes]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, fecha_cambio, usuario_modificador)
    SELECT 
        'Mensajes',
        d.id_mensaje,
        'DELETE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM DELETED d;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaMensajesInsert]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaMensajesInsert]
ON [dbo].[Mensajes]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Mensajes',
        i.id_mensaje,
        'INSERT',
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaMensajesUpdate]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaMensajesUpdate]
ON [dbo].[Mensajes]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Mensajes',
        i.id_mensaje,
        'UPDATE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i
    INNER JOIN DELETED d ON i.id_mensaje = d.id_mensaje;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaPermisosDelete]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaPermisosDelete]
ON [dbo].[Permisos]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, fecha_cambio, usuario_modificador)
    SELECT 
        'Permisos',
        d.id_permiso,
        'DELETE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM DELETED d;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaPermisosInsert]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaPermisosInsert]
ON [dbo].[Permisos]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Permisos',
        i.id_permiso,
        'INSERT',
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaPermisosUpdate]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaPermisosUpdate]
ON [dbo].[Permisos]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Permisos',
        i.id_permiso,
        'UPDATE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i
    INNER JOIN DELETED d ON i.id_permiso = d.id_permiso;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaPreguntasDelete]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaPreguntasDelete]
ON [dbo].[Preguntas]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, fecha_cambio, usuario_modificador)
    SELECT 
        'Preguntas',
        d.id_pregunta,
        'DELETE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM DELETED d;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaPreguntasInsert]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaPreguntasInsert]
ON [dbo].[Preguntas]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Preguntas',
        i.id_pregunta,
        'INSERT',
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaPreguntasUpdate]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaPreguntasUpdate]
ON [dbo].[Preguntas]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Preguntas',
        i.id_pregunta,
        'UPDATE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i
    INNER JOIN DELETED d ON i.id_pregunta = d.id_pregunta;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaSaldoPermisosDelete]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaSaldoPermisosDelete]
ON [dbo].[SaldoPermisos]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, fecha_cambio, usuario_modificador)
    SELECT 
        'SaldoPermisos',
        d.id_saldo,
        'DELETE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM DELETED d;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaSaldoPermisosInsert]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaSaldoPermisosInsert]
ON [dbo].[SaldoPermisos]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'SaldoPermisos',
        i.id_saldo,
        'INSERT',
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaSaldoPermisosUpdate]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaSaldoPermisosUpdate]
ON [dbo].[SaldoPermisos]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'SaldoPermisos',
        i.id_saldo,
        'UPDATE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i
    INNER JOIN DELETED d ON i.id_saldo = d.id_saldo;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaTiposPermisosDelete]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaTiposPermisosDelete]
ON [dbo].[TiposPermisos]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, fecha_cambio, usuario_modificador)
    SELECT 
        'TiposPermisos',
        d.id_tipo_permiso,
        'DELETE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM DELETED d;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaTiposPermisosInsert]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaTiposPermisosInsert]
ON [dbo].[TiposPermisos]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'TiposPermisos',
        i.id_tipo_permiso,
        'INSERT',
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i;
END;

GO
/****** Object:  Trigger [dbo].[AuditoriaTiposPermisosUpdate]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaTiposPermisosUpdate]
ON [dbo].[TiposPermisos]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'TiposPermisos',
        i.id_tipo_permiso,
        'UPDATE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i
    INNER JOIN DELETED d ON i.id_tipo_permiso = d.id_tipo_permiso;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaUsuariosDelete]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaUsuariosDelete]
ON [dbo].[Usuarios]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, fecha_cambio, usuario_modificador)
    SELECT 
        'Usuarios',
        d.id_usuario,
        'DELETE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM DELETED d;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaUsuariosInsert]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaUsuariosInsert]
ON [dbo].[Usuarios]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Usuarios',
        i.id_usuario,
        'INSERT',
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i;
END;
GO
/****** Object:  Trigger [dbo].[AuditoriaUsuariosUpdate]    Script Date: 4/23/2025 6:34:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[AuditoriaUsuariosUpdate]
ON [dbo].[Usuarios]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria (tabla_afectada, id_registro, tipo_accion, valores_anteriores, valores_nuevos, fecha_cambio, usuario_modificador)
    SELECT 
        'Usuarios',
        i.id_usuario,
        'UPDATE',
        (SELECT d.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        (SELECT i.* FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'),
        GETDATE(),
        SUSER_SNAME()
    FROM INSERTED i
    INNER JOIN DELETED d ON i.id_usuario = d.id_usuario;
END;
GO
USE [master]
GO
ALTER DATABASE [ProyectoRRHH] SET  READ_WRITE 
GO
