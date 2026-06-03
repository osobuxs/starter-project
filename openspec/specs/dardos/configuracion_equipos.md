# Especificación de Configuración Dinámica de Equipos

## ADDED Requirements

### Requirement: REQ-DART-001: Configuración dinámica de equipos

El sistema SHALL permitir al usuario configurar dinámicamente la cantidad de equipos (N) y la cantidad de jugadores por equipo (M) cuando `teamMode` es `true`.

#### Scenario: Configuración válida para equipos de 2

- GIVEN el usuario selecciona "modo equipos"
- WHEN selecciona 2 equipos
- AND selecciona 2 jugadores por equipo
- AND completa los nombres de los equipos y asigna 2 jugadores distintos a cada equipo
- THEN el sistema debe validar la configuración como exitosa

#### Scenario: Configuración inválida por tamaño incompleto

- GIVEN el usuario selecciona "modo equipos"
- WHEN selecciona 2 equipos
- AND selecciona 2 jugadores por equipo
- AND completa los nombres de los equipos
- AND asigna solo 1 jugador al equipo 1
- THEN el sistema debe mostrar un error "El equipo [nombre] debe tener exactamente 2 jugadores."

#### Scenario: Configuración inválida por jugador duplicado

- GIVEN el usuario selecciona "modo equipos"
- WHEN selecciona 2 equipos
- AND selecciona 2 jugadores por equipo
- AND completa los nombres de los equipos
- AND asigna al jugador "A" al equipo 1 y también al equipo 2
- THEN el sistema debe mostrar un error "El jugador A está asignado a más de un equipo."
