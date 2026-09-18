/*
 * ============================================================
 *  CLASE Planeta
 *  TEMA 1.6 — Aplicación: Ley de Gravitación Universal como
 *  campo vectorial (gravedad) + TEMA 1.1 — vector posición como
 *  función del tiempo, r(t), para las órbitas.
 *  ------------------------------------------------------------
 *  GRAVEDAD: cada planeta genera un vector de fuerza:
 *   - DIRECCIÓN: vector unitario del planeta al objeto atraído
 *     (normalizar(), TEMA 1.2).
 *   - MAGNITUD: F = G_GRAVEDAD * m1 * m2 / d² (TEMA 1.1: d es la
 *     magnitud de un vector). El "radio de colisión" para el
 *     cálculo es el radioVisual del planeta: no puedes acercarte
 *     más que a su superficie.
 *
 *  ÓRBITA (opcional, ver configurarOrbita()): el planeta recorre
 *  un círculo alrededor de otro Planeta (su "padre" orbital — el
 *  Sol, o la Tierra en el caso de la Luna), con una inclinación
 *  de plano para que no todos giren exactamente en el mismo
 *  plano (como en el sistema solar real).
 *
 *  Admite textura real (foto) o color sólido de respaldo si la
 *  imagen no se encontró (ver el aviso en consola).
 * ============================================================
 */
class Planeta {
  Vector3D posicion;
  float masa;         // Masa gravitacional (TEMA 1.6)
  float radioVisual;  // Tamaño de la esfera en pantalla Y radio mínimo de gravedad
  String nombre;

  PShape globo;
  boolean tieneTextura;
  color colorSolido;

  // --- Datos de órbita (0 = cuerpo fijo, como el Sol) ---
  Planeta padreOrbital;      // Alrededor de qué gira (null = alrededor del origen)
  float radioOrbita = 0;
  float velocidadAngular = 0;
  float anguloOrbital = 0;
  float inclinacionRad = 0;

  // --- Seguimiento de logros para Vuelo Libre (TEMA 1.1: ángulo como
  // función del vector posición relativo nave-planeta) ---
  boolean visitado = false;         // ¿ya te acercaste lo suficiente al menos una vez?
  boolean orbitaCompletada = false; // ¿diste una vuelta completa (360°) sin alejarte demasiado?
  float anguloAcumuladoOrbita = 0;
  float anguloAnteriorOrbita = 0;
  boolean rastreoOrbitaActivo = false;

  // Se llama cada cuadro en Vuelo Libre: si la nave está "cerca" del
  // planeta (ni pegada ni demasiado lejos), va sumando el ángulo que
  // recorre alrededor de él. Si llega a 360°, cuenta como una órbita.
  void actualizarSeguimientoOrbita(Nave nave) {
    Vector3D relativo = nave.posicion.calcularDistancia(this.posicion); // planeta -> nave
    float distancia = relativo.magnitud();
    float bandaMin = radioVisual + 40;
    float bandaMax = radioVisual * 6;

    if (distancia >= bandaMin && distancia <= bandaMax) {
      float anguloActual = atan2(relativo.y, relativo.x);
      if (rastreoOrbitaActivo) {
        float delta = anguloActual - anguloAnteriorOrbita;
        if (delta > PI) delta -= TWO_PI;   // normaliza el salto -PI/PI
        if (delta < -PI) delta += TWO_PI;
        anguloAcumuladoOrbita += abs(delta);
      }
      anguloAnteriorOrbita = anguloActual;
      rastreoOrbitaActivo = true;
      if (anguloAcumuladoOrbita >= TWO_PI) orbitaCompletada = true;
    } else {
      // Te saliste de la banda de distancia: hay que volver a dar la vuelta completa
      anguloAcumuladoOrbita = 0;
      rastreoOrbitaActivo = false;
    }
  }

  Planeta(String nombre, float x, float y, float z, float masa, float radioVisual, PImage textura) {
    this.nombre = nombre;
    posicion = new Vector3D(x, y, z);
    this.masa = masa;
    this.radioVisual = radioVisual;

    noStroke();
    globo = createShape(SPHERE, radioVisual);
    if (textura != null) {
      tieneTextura = true;
      globo.setTexture(textura);
    } else {
      tieneTextura = false;
      colorSolido = color(150, 150, 150);
      globo.setFill(colorSolido);
      println("Aviso: no se encontró la textura de " + nombre + ", usando color de respaldo.");
    }
  }

  Planeta(String nombre, float x, float y, float z, float masa, float radioVisual, color colorSolido) {
    this.nombre = nombre;
    posicion = new Vector3D(x, y, z);
    this.masa = masa;
    this.radioVisual = radioVisual;
    tieneTextura = false;
    this.colorSolido = colorSolido;

    noStroke();
    globo = createShape(SPHERE, radioVisual);
    globo.setFill(colorSolido);
  }

  // Activa la órbita circular alrededor de "padre" (o del origen si es null).
  // anguloInicialGrados: dónde arranca en su círculo (para que no queden
  // todos alineados). inclinacionGrados: qué tanto se inclina su plano
  // orbital respecto al plano XY (como las inclinaciones reales).
  void configurarOrbita(Planeta padre, float radio, float velAngular, float anguloInicialGrados, float inclinacionGrados) {
    this.padreOrbital = padre;
    this.radioOrbita = radio;
    this.velocidadAngular = velAngular;
    this.anguloOrbital = radians(anguloInicialGrados);
    this.inclinacionRad = radians(inclinacionGrados);
    recalcularPosicion(); // coloca el planeta en su lugar inicial de una vez
  }

  void recalcularPosicion() {
    Vector3D centro = (padreOrbital != null) ? padreOrbital.posicion : new Vector3D(0, 0, 0);
    float xOrb = radioOrbita * cos(anguloOrbital);
    float yOrb = radioOrbita * sin(anguloOrbital);
    posicion.x = centro.x + xOrb;
    posicion.y = centro.y + yOrb * cos(inclinacionRad);
    posicion.z = centro.z + yOrb * sin(inclinacionRad);
  }

  // TEMA 1.1: posición como función vectorial del tiempo, r(t).
  // Cada cuadro avanzamos el ángulo y recalculamos la posición.
  void actualizarOrbita() {
    if (radioOrbita <= 0) return; // Cuerpo fijo (el Sol)
    anguloOrbital += velocidadAngular;
    recalcularPosicion();
  }

  // Vector velocidad orbital instantánea (tangente al círculo):
  // es la derivada de r(t) respecto al tiempo. Se usa para dibujar
  // el vector velocidad de cada planeta en Modo Profesor.
  Vector3D velocidadOrbital() {
    if (radioOrbita <= 0) return new Vector3D(0, 0, 0);
    float vx = -radioOrbita * sin(anguloOrbital) * velocidadAngular;
    float vy =  radioOrbita * cos(anguloOrbital) * velocidadAngular * cos(inclinacionRad);
    float vz =  radioOrbita * cos(anguloOrbital) * velocidadAngular * sin(inclinacionRad);
    return new Vector3D(vx, vy, vz);
  }

  Vector3D calcularAtraccion(Nave nave) {
    Vector3D fuerza = posicion.calcularDistancia(nave.posicion);
    float distancia = max(fuerza.magnitud(), this.radioVisual); // no puedes acercarte más que la superficie
    fuerza.normalizar();
    float fuerzaGravedad = (G_GRAVEDAD * this.masa * nave.masa) / (distancia * distancia);
    fuerza.multiplicar(fuerzaGravedad);
    return fuerza;
  }

  Vector3D calcularGravedadEnPunto(Vector3D puntoEspacio) {
    Vector3D fuerza = posicion.calcularDistancia(puntoEspacio);
    float distancia = max(fuerza.magnitud(), this.radioVisual);
    fuerza.normalizar();
    float fuerzaGravedad = (G_GRAVEDAD * this.masa * 1.0) / (distancia * distancia);
    fuerza.multiplicar(fuerzaGravedad);
    return fuerza;
  }

  void dibujar() {
    pushMatrix();
    translate(posicion.x, posicion.y, posicion.z);
    rotateY(frameCount * 0.005);
    shape(globo);
    popMatrix();
  }
}
