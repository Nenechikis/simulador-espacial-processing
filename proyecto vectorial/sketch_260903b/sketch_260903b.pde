/*
 * ============================================================
 *  SIMULADOR VECTORIAL ESPACIAL
 *  Proyecto de Cálculo Vectorial — cubre los temas 1.1 a 1.6
 *
 *  MAPA DE TEMAS -> ARCHIVO:
 *   1.1 Vector en el plano y el espacio  -> Vector3D.pde, Planeta.pde (órbitas)
 *   1.2 Álgebra vectorial y su geometría -> Vector3D.pde, Nave.pde
 *   1.3 Producto escalar y vectorial     -> Vector3D.pde (usado aquí, TELEMETRÍA)
 *   1.4 Ecuación de la recta             -> este archivo (telemetría, Pizarrón)
 *   1.5 Ecuación del plano               -> este archivo (telemetría)
 *   1.6 Aplicaciones                     -> Planeta.pde, TanqueCombustible.pde
 *
 *  ESTADOS (estadoJuego):
 *   0 Menú Principal
 *   1 Vuelo Libre (sandbox)
 *   2 Modo Misión: selección de objetivo (Luna/Venus/Marte/Mercurio/
 *     Júpiter/Saturno/Urano/Neptuno)
 *   3 Modo Misión: Pizarrón (calculas V a mano y la escribes)
 *   4 Modo Misión: Simulación (se reproduce tu cálculo con gravedad real)
 *   5 Modo Misión: Resultado (qué tan cerca quedaste del objetivo)
 *  'ESPACIO' = Modo Profesor (plano cartesiano, campo vectorial, telemetría,
 *  vectores de velocidad de cada planeta).
 *
 *  NOTA: el agujero negro (AgujeroNegro.pde) se quitó del juego por
 *  decisión del equipo — el archivo sigue en el proyecto por si lo
 *  necesitan más adelante, pero ya no se instancia ni se dibuja.
 *
 *  ---------------------------------------------------------------
 *  IMÁGENES NECESARIAS (carpeta data/):
 *  tierra.jpg, marte.jpg (ya las tienen) + sol.jpg, mercurio.jpg,
 *  venus.jpg, luna.jpg, jupiter.jpg, saturno.jpg, urano.jpg,
 *  neptuno.jpg
 *  Gratis (CC-BY 4.0) en https://www.solarsystemscope.com/textures/
 *  (versión "2k" de cada uno). Si falta un archivo, el programa NO
 *  truena: usa un color de respaldo.
 *
 *  ---------------------------------------------------------------
 *  ESCALA: tamaños y distancias A ESCALA COMPRIMIDA (raíz cuadrada
 *  de los valores reales), no astronómica exacta — a escala real
 *  el mapa sería injugable. Se conserva el ORDEN y las proporciones
 *  relativas correctas. Explicarlo así en la presentación.
 * ============================================================
 */
Nave miNave;
ArrayList<Planeta> planetas; // Sol + los 8 planetas + la Luna, en orden real
ArrayList<TanqueCombustible> tanques; // Solo se llenan en Vuelo Libre
Planeta sol, mercurio, venus, tierra, luna, marte, jupiter, saturno, urano, neptuno;
Planeta objetivoMision; // A cuál cuerpo le apuntamos en el Modo Misión / la telemetría (por defecto, Marte)
boolean modoProfesor = false;

// Puntos y logros de Vuelo Libre (visitar planetas / completar órbitas)
int puntos = 0;
String mensajeLogro = "";
int mensajeLogroFrame = -9999;

int estadoJuego = 0;

// Escritura de decimales a mano (más precisa que incrementos fijos):
// el jugador teclea el número como en una calculadora. 7 campos:
// 0 Vx, 1 Vy, 2 Vz, 3 |V|, 4 X(200), 5 Y(200), 6 Z(200)
String[] bufferCampos = {"", "", "", "", "", "", ""};
float[] inputCampos = new float[7];
int campoActivo = 0;
Vector3D posInicialCalculo; // dónde estaba la nave cuando calcularon (para verificar después)

// TEMA 1.6: constante de gravitación del "universo" del juego, en UN
// solo lugar para poder tunear el feeling de vuelo fácilmente.
float G_GRAVEDAD = 45.0;

// El Pizarrón calcula V asumiendo CERO gravedad (línea recta). En la
// realidad, los 9 cuerpos (sobre todo el Sol) desvían bastante esa
// línea recta, y una ruta que pase cerca del Sol (p. ej. Tierra ->
// Mercurio, el caso más extremo por ser el planeta más cercano al Sol)
// se aleja demasiado del cálculo aunque esté bien hecho. Por eso, SOLO
// durante la Misión (no en Vuelo Libre, que sigue con gravedad 100%
// real) atenuamos la fuerza total a este porcentaje.
// El Pizarrón calcula V asumiendo CERO gravedad (línea recta) — es lo
// único que enseña el curso (álgebra vectorial), no mecánica orbital.
// Para que ese cálculo tenga sentido, durante la Misión SOLO actúa la
// gravedad del planeta OBJETIVO (ni la Tierra, ni el Sol, ni los demás
// de paso) — así el viaje es casi la línea recta que calcularon, y
// cerca del final el objetivo los "atrapa" un poco con su propia
// gravedad (aplicación real del tema 1.6, sin desviar todo el viaje).
// Vuelo Libre no usa esto — ahí siempre actúan los 9 cuerpos reales.
float FACTOR_CAPTURA_OBJETIVO = 0.6;

// Tamaño de las tablas de texto (Pizarrón y Telemetría del Modo
// Profesor). Se ajusta con las teclas '+' y '-' en cualquier momento.
float escalaUI = 1.0;

float LIMITE_MUNDO = 8500;

// Seguimiento del resultado de la misión (para la pantalla de Resultado)
float distanciaMinimaAlcanzada;
int framesSimulacion;
final int MAX_FRAMES_SIMULACION = 1400; // ~23s a 60fps: si no llegaste, se acaba el tiempo

float[] estrellasX = new float[1200];
float[] estrellasY = new float[1200];
float[] estrellasZ = new float[1200];

float camX = 0;
float camY = 0;
float zoom = -2600;
float SENSIBILIDAD_ARRASTRE = 2.2;
float SENSIBILIDAD_ZOOM = 220;

PImage fotoSol, fotoMercurio, fotoVenus, fotoTierra, fotoLuna, fotoMarte, fotoJupiter, fotoSaturno, fotoUrano, fotoNeptuno;

void setup() {
  size(800, 600, P3D);
  textureMode(NORMAL);

  fotoSol      = loadImage("sol.jpg");
  fotoMercurio = loadImage("mercurio.jpg");
  fotoVenus    = loadImage("venus.jpg");
  fotoTierra   = loadImage("tierra.jpg");
  fotoLuna     = loadImage("luna.jpg");
  fotoMarte    = loadImage("marte.jpg");
  fotoJupiter  = loadImage("jupiter.jpg");
  fotoSaturno  = loadImage("saturno.jpg");
  fotoUrano    = loadImage("urano.jpg");
  fotoNeptuno  = loadImage("neptuno.jpg");

  for (int i = 0; i < estrellasX.length; i++) {
    estrellasX[i] = random(-LIMITE_MUNDO, LIMITE_MUNDO);
    estrellasY[i] = random(-LIMITE_MUNDO, LIMITE_MUNDO);
    estrellasZ[i] = random(-3500, 0);
  }
  reiniciarNivel(0);
}

void reiniciarNivel(int nuevoEstado) {
  estadoJuego = nuevoEstado;

  // ---- SISTEMA SOLAR, en orden real, escala comprimida (ver cabecera) ----
  planetas = new ArrayList<Planeta>();

  sol = new Planeta("Sol", 0, 0, 0, 260, 300, fotoSol);
  planetas.add(sol);

  mercurio = new Planeta("Mercurio", 0, 0, 0, 20, 25, fotoMercurio);
  mercurio.configurarOrbita(sol, 700, 0.0030, 40, 7.0);
  planetas.add(mercurio);

  venus = new Planeta("Venus", 0, 0, 0, 42, 39, fotoVenus);
  venus.configurarOrbita(sol, 1100, 0.0022, 160, 3.4);
  planetas.add(venus);

  tierra = new Planeta("Tierra", 0, 0, 0, 50, 40, fotoTierra);
  tierra.configurarOrbita(sol, 1550, 0.0015, 0, 0.0);
  planetas.add(tierra);

  luna = new Planeta("Luna", 0, 0, 0, 6, 14, fotoLuna);
  luna.configurarOrbita(tierra, 150, 0.0080, 0, 5.0);
  planetas.add(luna);

  marte = new Planeta("Marte", 0, 0, 0, 30, 29, fotoMarte);
  marte.configurarOrbita(sol, 2050, 0.0012, 260, 1.9);
  planetas.add(marte);

  jupiter = new Planeta("Jupiter", 0, 0, 0, 140, 130, fotoJupiter);
  jupiter.configurarOrbita(sol, 3200, 0.0006, 90, 1.3);
  planetas.add(jupiter);

  saturno = new Planeta("Saturno", 0, 0, 0, 115, 120, fotoSaturno);
  saturno.configurarOrbita(sol, 4300, 0.0004, 200, 2.5);
  planetas.add(saturno);

  urano = new Planeta("Urano", 0, 0, 0, 70, 80, fotoUrano);
  urano.configurarOrbita(sol, 5400, 0.0003, 310, 0.8);
  planetas.add(urano);

  neptuno = new Planeta("Neptuno", 0, 0, 0, 75, 78, fotoNeptuno);
  neptuno.configurarOrbita(sol, 6500, 0.0002, 30, 1.8);
  planetas.add(neptuno);

  objetivoMision = marte; // valor por defecto (usado también por la telemetría en Vuelo Libre)

  // Tanques de combustible: solo tienen sentido en Vuelo Libre (en el
  // Modo Misión el combustible no se gasta, es un solo impulso inicial).
  tanques = new ArrayList<TanqueCombustible>();
  if (nuevoEstado == 1) {
    for (int i = 0; i < 14; i++) {
      float tx = random(-6000, 6000);
      float ty = random(-6000, 6000);
      float tz = random(-600, 600);
      tanques.add(new TanqueCombustible(tx, ty, tz));
    }
  }

  puntos = 0;
  mensajeLogro = "";
  mensajeLogroFrame = -9999;

  reiniciarNave();
  if (estadoJuego == 1) miNave.velocidad = new Vector3D(2.0, 0, 0);

  camX = 0; camY = 0; zoom = -2600;
}

// Vuelve a poner la nave "despegando" de la Tierra, sin reconstruir
// todo el sistema solar. Se usa al reintentar una misión.
// NOTA: arranca a 420 unidades del centro de la Tierra — a propósito
// MÁS LEJOS que la órbita de la Luna (radio 150). Si arranca dentro
// del "carril" de la Luna, la gravedad combinada de la Tierra y la
// Luna a corta distancia es tan fuerte que atrapa casi cualquier
// velocidad calculada con la fórmula simple del Pizarrón (que ignora
// la gravedad a propósito) — la nave nunca lograba escapar.
void reiniciarNave() {
  miNave = new Nave(tierra.posicion.x, tierra.posicion.y - 420, tierra.posicion.z);
  miNave.velocidad = new Vector3D(0, 0, 0);
}

void draw() {
  background(5, 5, 12);

  // Las órbitas SOLO avanzan en el Menú (para lucirse) y en Vuelo Libre.
  // Se CONGELAN durante el Modo Misión completo (selección/pizarrón/
  // simulación/resultado): el Reto asume que el objetivo no se mueve
  // mientras calculas a mano.
  if (estadoJuego == 0 || estadoJuego == 1) {
    for (Planeta p : planetas) p.actualizarOrbita();
  }

  miNave.estaPropulsando = false;
  if (estadoJuego == 1 && keyPressed) {
    if (key == 'w' || key == 'W') miNave.propulsar(0, -0.03, 0);
    if (key == 's' || key == 'S') miNave.propulsar(0, 0.03, 0);
    if (key == 'a' || key == 'A') miNave.propulsar(-0.03, 0, 0);
    if (key == 'd' || key == 'D') miNave.propulsar(0.03, 0, 0);
    if (key == 'q' || key == 'Q') miNave.propulsar(0, 0, -0.03);
    if (key == 'e' || key == 'E') miNave.propulsar(0, 0, 0.03);
  }

  pushMatrix();
  translate(width/2 + camX, height/2 + camY, zoom);
  directionalLight(255, 255, 255, 1, 1, -1);
  ambientLight(40, 40, 50);

  stroke(255, 255, 255, 150); strokeWeight(2);
  for (int i = 0; i < estrellasX.length; i++) point(estrellasX[i], estrellasY[i], estrellasZ[i]);
  noStroke();

  if (modoProfesor) {
    dibujarPlanoCartesiano();
    dibujarCampoVectorial();
  }

  dibujarOrbitas();

  Vector3D fuerzaNeta = new Vector3D(0, 0, 0);
  if (estadoJuego == 1) {
    // VUELO LIBRE: los 9 cuerpos gravitan de verdad, sin atenuar.
    for (Planeta p : planetas) fuerzaNeta.sumar(p.calcularAtraccion(miNave));
    if (miNave.viva) {
      miNave.aplicarFuerza(fuerzaNeta);
      miNave.actualizar();
    }
  } else if (estadoJuego == 4) {
    // MISIÓN: solo gravita el objetivo (ver comentario junto a
    // FACTOR_CAPTURA_OBJETIVO) — así el viaje respeta la línea recta
    // que calcularon, y solo se curva un poco al llegar.
    Vector3D fuerzaCaptura = objetivoMision.calcularAtraccion(miNave);
    fuerzaCaptura.multiplicar(FACTOR_CAPTURA_OBJETIVO);
    fuerzaNeta.sumar(fuerzaCaptura);
    if (miNave.viva) {
      miNave.aplicarFuerza(fuerzaNeta);
      miNave.actualizar();
    }
    // Seguimiento del resultado de la misión (para la pantalla de Resultado)
    if (estadoJuego == 4 && miNave.viva) {
      float distanciaActual = objetivoMision.posicion.calcularDistancia(miNave.posicion).magnitud();
      distanciaMinimaAlcanzada = min(distanciaMinimaAlcanzada, distanciaActual);
      framesSimulacion++;
    }
  }

  for (Planeta p : planetas) p.dibujar();
  if (estadoJuego != 0) miNave.dibujar();

  if (estadoJuego == 1) {
    for (TanqueCombustible t : tanques) {
      t.verificarColision(miNave);
      t.dibujar();
    }
    revisarLogros();
  }

  if (modoProfesor) {
    for (Planeta p : planetas) {
      if (p.radioOrbita <= 0) continue;
      Vector3D vOrb = p.velocidadOrbital();
      pushMatrix();
      translate(p.posicion.x, p.posicion.y, p.posicion.z);
      stroke(0, 255, 255); strokeWeight(3);
      line(0, 0, 0, vOrb.x * 300, vOrb.y * 300, vOrb.z * 300);
      popMatrix();
    }
    if (estadoJuego != 0) miNave.dibujarVectores(fuerzaNeta);
  }
  popMatrix();

  // --- INTERFAZ UI ---
  if (estadoJuego == 0) {
    dibujarMenuPrincipal();
  } else if (estadoJuego == 1) {
    fill(255); textSize(14);
    text("MODO VUELO LIBRE | Mover: WASD (plano) + Q/E (profundidad) | Menú: 'M'", 20, 30);
    text("Objetivo de referencia (para el ángulo del Modo Profesor): teclas 1-8", 20, 50);
    text("Combustible: " + nf(max(0, miNave.combustible), 0, 1) + " L   |   Puntos: " + puntos, 20, height - 20);
    if (frameCount - mensajeLogroFrame < 180) {
      fill(255, 220, 0); textSize(16); textAlign(CENTER);
      text(mensajeLogro, width/2, 70);
      textAlign(LEFT);
    }
    verificarLimitesVueloLibre();
  } else if (estadoJuego == 2) {
    dibujarSeleccionObjetivo();
  } else if (estadoJuego == 3) {
    dibujarPizarronCalculo();
  } else if (estadoJuego == 4) {
    fill(255); textSize(14);
    text("SIMULANDO TRAYECTORIA HACIA " + objetivoMision.nombre.toUpperCase() + "... | Menú: 'M'", 20, 30);
    verificarFinMision();
  } else if (estadoJuego == 5) {
    dibujarResultadoMision();
  }

  // TELEMETRÍA MODO PROFESOR (Cubre 1.3, 1.4 y 1.5 del Temario)
  if (modoProfesor && (estadoJuego == 1 || estadoJuego == 4)) {
    pushMatrix();
    scale(escalaUI); // '+' / '-' para hacerla más grande o más chica
    fill(0, 200, 255); textSize(14);
    text("====== TELEMETRÍA MATEMÁTICA AVANZADA ( ] [ zoom) ======", 20, 80);

    fill(255);
    text("Vector Posición (r): " + nf(miNave.posicion.x, 0, 1) + "i, " + nf(miNave.posicion.y, 0, 1) + "j, " + nf(miNave.posicion.z, 0, 1) + "k", 20, 105);
    fill(0, 255, 0);
    text("Vector Velocidad (v): " + nf(miNave.velocidad.x, 0, 2) + "i, " + nf(miNave.velocidad.y, 0, 2) + "j, " + nf(miNave.velocidad.z, 0, 2) + "k", 20, 125);
    fill(255, 255, 0);
    text("Fuerza Neta (F): " + nf(fuerzaNeta.x, 0, 2) + "i, " + nf(fuerzaNeta.y, 0, 2) + "j, " + nf(fuerzaNeta.z, 0, 2) + "k", 20, 145);

    fill(255, 150, 255);
    text("1.4 Ecuación de la Recta (Trayectoria):", 20, 175);
    text("x = " + nf(miNave.posicion.x, 0, 1) + " + " + nf(miNave.velocidad.x, 0, 2) + " t", 30, 195);
    text("y = " + nf(miNave.posicion.y, 0, 1) + " + " + nf(miNave.velocidad.y, 0, 2) + " t", 30, 215);
    text("z = " + nf(miNave.posicion.z, 0, 1) + " + " + nf(miNave.velocidad.z, 0, 2) + " t", 30, 235);

    Vector3D normalOrbital = miNave.posicion.productoCruz(miNave.velocidad);
    fill(255, 100, 100);
    text("1.3 Producto Cruz (r x v) -> Vector Normal:", 20, 265);
    text("N = " + nf(normalOrbital.x, 0, 1) + "i, " + nf(normalOrbital.y, 0, 1) + "j, " + nf(normalOrbital.z, 0, 1) + "k", 30, 285);

    fill(100, 255, 255);
    text("1.5 Ecuación del Plano Orbital:", 20, 315);
    if (normalOrbital.magnitud() < 0.001) {
      text("(r y v son paralelos: trayectoria rectilínea, plano no definido)", 30, 335);
    } else {
      float D = -(normalOrbital.x * miNave.posicion.x + normalOrbital.y * miNave.posicion.y + normalOrbital.z * miNave.posicion.z);
      text(nf(normalOrbital.x, 0, 1) + "x + " + nf(normalOrbital.y, 0, 1) + "y + " + nf(normalOrbital.z, 0, 1) + "z + (" + nf(D, 0, 1) + ") = 0", 30, 335);
    }

    Vector3D vectorHaciaObjetivo = objetivoMision.posicion.calcularDistancia(miNave.posicion);
    float anguloGrados = degrees(miNave.velocidad.anguloEntre(vectorHaciaObjetivo));
    fill(150, 255, 100);
    text("1.3 Aplicación de Producto Punto (Ángulo de Desviación):", 20, 365);
    text("Ángulo Nave-" + objetivoMision.nombre + ": " + nf(anguloGrados, 0, 2) + "° (0° es rumbo perfecto)", 30, 385);
    popMatrix();
  }
}

void dibujarMenuPrincipal() {
  fill(0, 0, 0, 170); noStroke();
  rect(0, height/2 - 160, width, 340);

  fill(0, 200, 255);
  textSize(34); textAlign(CENTER);
  text("SIMULADOR VECTORIAL ESPACIAL", width/2, height/2 - 100);
  fill(180); textSize(12);
  text("Sol · Mercurio · Venus · Tierra+Luna · Marte · Júpiter · Saturno · Urano · Neptuno", width/2, height/2 - 68);
  fill(255); textSize(20);
  text("1. MODO VUELO LIBRE (Sandbox)", width/2, height/2 - 10);
  text("2. MODO MISIÓN (Educativo)", width/2, height/2 + 30);
  fill(150); textSize(13);
  text("Presiona 1 o 2 para empezar | 'ESPACIO' activa el Modo Profesor", width/2, height/2 + 90);
  textAlign(LEFT);
}

// TEMA 1.6: elegir el objetivo es elegir con qué cuerpo vamos a
// trabajar la aplicación de vectores (distinta masa, distinta
// distancia = distinto reto).
void dibujarSeleccionObjetivo() {
  fill(0, 0, 0, 210); rect(60, 70, 680, 400);
  fill(0, 200, 255); textSize(22); textAlign(CENTER);
  text("MODO MISIÓN — Elige tu objetivo", width/2, 110);
  textAlign(LEFT); fill(255); textSize(14);
  text("1. Luna       (cercana, ideal para empezar)      dist: " + nf(luna.posicion.calcularDistancia(miNave.posicion).magnitud(), 0, 0) + " u", 100, 150);
  text("2. Venus      (dificultad media)                 dist: " + nf(venus.posicion.calcularDistancia(miNave.posicion).magnitud(), 0, 0) + " u", 100, 182);
  text("3. Marte      (el clásico)                        dist: " + nf(marte.posicion.calcularDistancia(miNave.posicion).magnitud(), 0, 0) + " u", 100, 214);
  text("4. Mercurio   (difícil: rápido y cerca del Sol)  dist: " + nf(mercurio.posicion.calcularDistancia(miNave.posicion).magnitud(), 0, 0) + " u", 100, 246);
  text("5. Júpiter    (lejos, blanco enorme)              dist: " + nf(jupiter.posicion.calcularDistancia(miNave.posicion).magnitud(), 0, 0) + " u", 100, 278);
  text("6. Saturno    (lejos, blanco enorme)              dist: " + nf(saturno.posicion.calcularDistancia(miNave.posicion).magnitud(), 0, 0) + " u", 100, 310);
  text("7. Urano      (muy lejos)                         dist: " + nf(urano.posicion.calcularDistancia(miNave.posicion).magnitud(), 0, 0) + " u", 100, 342);
  text("8. Neptuno    (el más lejano: máxima dificultad) dist: " + nf(neptuno.posicion.calcularDistancia(miNave.posicion).magnitud(), 0, 0) + " u", 100, 374);
  fill(180); textSize(13);
  text("Presiona el número de tu objetivo | 'M': Menú", 100, 430);
}

void dibujarPizarronCalculo() {
  pushMatrix();
  scale(escalaUI); // ] [ para hacerla más grande o más chica
  fill(0, 0, 0, 225); rect(10, 10, 520, 450);
  fill(255, 200, 0); textSize(17); text("RETO: CINEMÁTICA VECTORIAL — Objetivo: " + objetivoMision.nombre, 25, 35);
  fill(255); textSize(13);
  text("Calcula V para llegar en t=400s (línea recta; el objetivo atrae un poco al final).", 25, 58);

  fill(0, 255, 255); textSize(13); text("1) FÓRMULA (tema 1.2):  V = (Posición Final - Posición Inicial) / t", 25, 88);
  fill(255);
  text("Vx = ( " + nf(objetivoMision.posicion.x, 0, 0) + " - " + nf(miNave.posicion.x, 0, 0) + " ) / 400 = ?", 30, 108);
  text("Vy = ( " + nf(objetivoMision.posicion.y, 0, 0) + " - " + nf(miNave.posicion.y, 0, 0) + " ) / 400 = ?", 30, 128);
  text("Vz = ( " + nf(objetivoMision.posicion.z, 0, 0) + " - " + nf(miNave.posicion.z, 0, 0) + " ) / 400 = ?  (el objetivo no siempre está en z=0)", 30, 148);

  fill(0, 255, 255); text("2) MAGNITUD (tema 1.1):  |V| = √(Vx² + Vy² + Vz²)   (tu rapidez)", 25, 176);
  fill(0, 255, 255); text("3) ECUACIÓN DE LA RECTA (tema 1.4): ¿dónde estarás en t=200?", 25, 198);
  fill(255);
  text("x(200)=" + nf(miNave.posicion.x, 0, 0) + "+Vx·200   y(200)=" + nf(miNave.posicion.y, 0, 0) + "+Vy·200   z(200)=" + nf(miNave.posicion.z, 0, 0) + "+Vz·200", 30, 218);

  fill(50, 255, 50); textSize(14); text("ESCRIBE TUS RESPUESTAS (números, '.', '-'):", 25, 248);

  boolean parpadeo = (frameCount / 20) % 2 == 0;
  String cursor = parpadeo ? "_" : " ";

  String[] etiquetas = {"Vx", "Vy", "Vz", "|V|", "X(200)", "Y(200)", "Z(200)"};
  int[] xPos = {25, 175, 325, 25, 25,  190, 355};
  int[] yPos = {275, 275, 275, 305, 335, 335, 335};

  textSize(14);
  for (int i = 0; i < 7; i++) {
    fill(campoActivo == i ? color(255, 255, 0) : color(150));
    text(etiquetas[i] + ": " + bufferCampos[i] + (campoActivo == i ? cursor : ""), xPos[i], yPos[i]);
  }

  fill(255, 100, 100); textSize(13);
  text("TAB: siguiente campo | BACKSPACE: borrar | ENTER: iniciar | 'M': Menú", 25, 380);
  fill(180); textSize(12);
  text("(2, 3 y 4 no afectan el vuelo — Vx/Vy/Vz sí. ] [ : zoom)", 25, 400);
  popMatrix();
}

// Pantalla de resultado: qué tan cerca quedaste del objetivo, y si tus
// respuestas extra (magnitud y predicción de posición, ya en 3D) fueron
// correctas.
void dibujarResultadoMision() {
  boolean exito = distanciaMinimaAlcanzada < (objetivoMision.radioVisual + 70);
  float margenError = max(0, distanciaMinimaAlcanzada - objetivoMision.radioVisual);

  // Valores "reales" para comparar contra lo que escribieron
  float vx = inputCampos[0], vy = inputCampos[1], vz = inputCampos[2];
  float magReal = sqrt(vx * vx + vy * vy + vz * vz);
  float x200Real = posInicialCalculo.x + vx * 200;
  float y200Real = posInicialCalculo.y + vy * 200;
  float z200Real = posInicialCalculo.z + vz * 200;
  boolean magOk = esCorrecto(inputCampos[3], magReal);
  boolean x200Ok = esCorrecto(inputCampos[4], x200Real);
  boolean y200Ok = esCorrecto(inputCampos[5], y200Real);
  boolean z200Ok = esCorrecto(inputCampos[6], z200Real);

  fill(0, 0, 0, 230); rect(120, 90, 560, 380);
  textAlign(CENTER);
  fill(exito ? color(50, 255, 50) : color(255, 80, 80));
  textSize(24);
  text(exito ? "¡MISIÓN CUMPLIDA!" : "OBJETIVO NO ALCANZADO", width/2, 135);

  fill(255); textSize(15);
  text("Objetivo: " + objetivoMision.nombre, width/2, 168);
  text("Distancia mínima alcanzada: " + nf(distanciaMinimaAlcanzada, 0, 1) + " u", width/2, 192);
  fill(255, 220, 100);
  text("Margen de error: " + nf(margenError, 0, 1) + " u", width/2, 216);

  fill(0, 200, 255); textSize(15); text("VERIFICACIÓN DE TUS CÁLCULOS EXTRA", width/2, 250);
  textAlign(LEFT); textSize(13);
  fill(magOk ? color(80, 255, 80) : color(255, 100, 100));
  text((magOk ? "✓ " : "✗ ") + "Magnitud |V|: escribiste " + nf(inputCampos[3], 0, 3) + " — real: " + nf(magReal, 0, 3), 150, 278);
  fill(x200Ok ? color(80, 255, 80) : color(255, 100, 100));
  text((x200Ok ? "✓ " : "✗ ") + "X(200): escribiste " + nf(inputCampos[4], 0, 1) + " — real: " + nf(x200Real, 0, 1), 150, 300);
  fill(y200Ok ? color(80, 255, 80) : color(255, 100, 100));
  text((y200Ok ? "✓ " : "✗ ") + "Y(200): escribiste " + nf(inputCampos[5], 0, 1) + " — real: " + nf(y200Real, 0, 1), 150, 322);
  fill(z200Ok ? color(80, 255, 80) : color(255, 100, 100));
  text((z200Ok ? "✓ " : "✗ ") + "Z(200): escribiste " + nf(inputCampos[6], 0, 1) + " — real: " + nf(z200Real, 0, 1), 150, 344);

  textAlign(CENTER);
  fill(200); textSize(14);
  text("'R': reintentar con nuevos cálculos | 'M': Menú", width/2, 445);
  textAlign(LEFT);
}

// Tolerancia proporcional: sirve tanto para magnitudes chiquitas (0.03)
// como para posiciones grandes (miles de unidades).
boolean esCorrecto(float valorEstudiante, float valorReal) {
  float tolerancia = max(0.02, abs(valorReal) * 0.03);
  return abs(valorEstudiante - valorReal) <= tolerancia;
}

// Solo para Vuelo Libre: si te alejas demasiado, se acabó.
void verificarLimitesVueloLibre() {
  if (miNave.posicion.magnitud() > LIMITE_MUNDO && miNave.viva) {
    fill(255, 50, 50); textSize(28); textAlign(CENTER);
    text("¡PERDIDO EN EL ESPACIO! Presiona 'M' para volver al menú", width/2, height/2);
    textAlign(LEFT);
    miNave.viva = false;
  }
}

// Para el Modo Misión: detecta el fin (llegada, perdido, o se acabó
// el tiempo) y pasa a la pantalla de Resultado.
void verificarFinMision() {
  boolean termino = false;
  if (miNave.posicion.magnitud() > LIMITE_MUNDO) termino = true;
  if (objetivoMision.posicion.calcularDistancia(miNave.posicion).magnitud() < objetivoMision.radioVisual + 70) termino = true;
  if (framesSimulacion >= MAX_FRAMES_SIMULACION) termino = true;

  if (termino) {
    miNave.viva = false;
    estadoJuego = 5;
  }
}

// Limpia el cuaderno de escritura cada vez que empiezan un cálculo nuevo
void iniciarPizarron() {
  for (int i = 0; i < 7; i++) bufferCampos[i] = "";
  campoActivo = 0;
  estadoJuego = 3;
}

// Convierte lo que escribieron a número, sin tronar si está vacío o
// a medio escribir (por ejemplo, si solo pusieron "-" o "." todavía).
float textoAFloat(String s) {
  if (s == null || s.length() == 0 || s.equals("-") || s.equals(".") || s.equals("-.")) return 0;
  try {
    return Float.parseFloat(s);
  } catch (Exception e) {
    return 0;
  }
}

// Solo corre en Vuelo Libre: detecta la primera vez que te acercas a un
// planeta (visita) y la primera vez que completas una vuelta de 360°
// alrededor de uno (órbita), y reparte puntos por cada logro nuevo.
void revisarLogros() {
  for (Planeta p : planetas) {
    float distancia = p.posicion.calcularDistancia(miNave.posicion).magnitud();

    if (!p.visitado && distancia < p.radioVisual + 30) {
      p.visitado = true;
      puntos += 50;
      mensajeLogro = "¡Logro! Visitaste " + p.nombre + " (+50 pts)";
      mensajeLogroFrame = frameCount;
    }

    boolean yaCompletadaAntes = p.orbitaCompletada;
    p.actualizarSeguimientoOrbita(miNave);
    if (p.orbitaCompletada && !yaCompletadaAntes) {
      puntos += 100;
      mensajeLogro = "¡Logro! Completaste una órbita alrededor de " + p.nombre + " (+100 pts)";
      mensajeLogroFrame = frameCount;
    }
  }
}

void keyPressed() {
  // Zoom de las tablas de texto (Pizarrón y Telemetría del Modo Profesor)
  // — funciona en cualquier pantalla. Se usan corchetes, no +/-, para no
  // chocar con el signo "-" que se escribe en los campos del Pizarrón.
  if (key == ']') escalaUI = min(1.6, escalaUI + 0.1);
  if (key == '[') escalaUI = max(1.0, escalaUI - 0.1);

  if (estadoJuego == 0) {
    if (key == '1') reiniciarNivel(1);
    if (key == '2') reiniciarNivel(2);
  } else if (estadoJuego == 1) {
    // Elegir a qué cuerpo le mide el ángulo/distancia la telemetría del
    // Modo Profesor — no afecta el vuelo, solo qué se muestra en pantalla.
    if (key == '1') objetivoMision = luna;
    if (key == '2') objetivoMision = venus;
    if (key == '3') objetivoMision = marte;
    if (key == '4') objetivoMision = mercurio;
    if (key == '5') objetivoMision = jupiter;
    if (key == '6') objetivoMision = saturno;
    if (key == '7') objetivoMision = urano;
    if (key == '8') objetivoMision = neptuno;
  } else if (estadoJuego == 2) {
    if (key == '1') { objetivoMision = luna;     iniciarPizarron(); }
    if (key == '2') { objetivoMision = venus;    iniciarPizarron(); }
    if (key == '3') { objetivoMision = marte;    iniciarPizarron(); }
    if (key == '4') { objetivoMision = mercurio; iniciarPizarron(); }
    if (key == '5') { objetivoMision = jupiter;  iniciarPizarron(); }
    if (key == '6') { objetivoMision = saturno;  iniciarPizarron(); }
    if (key == '7') { objetivoMision = urano;    iniciarPizarron(); }
    if (key == '8') { objetivoMision = neptuno;  iniciarPizarron(); }
  } else if (estadoJuego == 3) {
    // TEMA 1.1: escriben el número tal cual, como en una calculadora
    // — mucho más preciso que subir de 0.5 en 0.5 cuando el resultado
    // real es algo como 0.0375.
    if (key == TAB) {
      campoActivo = (campoActivo + 1) % 7; // Vx->Vy->Vz->|V|->X(200)->Y(200)->Z(200)->Vx...
    } else if (key == BACKSPACE) {
      if (bufferCampos[campoActivo].length() > 0) {
        bufferCampos[campoActivo] = bufferCampos[campoActivo].substring(0, bufferCampos[campoActivo].length() - 1);
      }
    } else if ((key >= '0' && key <= '9') || key == '.' || key == '-') {
      if (bufferCampos[campoActivo].length() < 9) bufferCampos[campoActivo] += key;
    } else if (key == ENTER || key == RETURN) {
      for (int i = 0; i < 7; i++) inputCampos[i] = textoAFloat(bufferCampos[i]);
      posInicialCalculo = new Vector3D(miNave.posicion.x, miNave.posicion.y, miNave.posicion.z);
      // TEMA 1.1: ahora sí es un vector 3D completo — Vz ya no se ignora.
      miNave.velocidad = new Vector3D(inputCampos[0], inputCampos[1], inputCampos[2]);
      distanciaMinimaAlcanzada = 999999;
      framesSimulacion = 0;
      estadoJuego = 4;
    }
  }
}

void keyReleased() {
  if (key == ' ') modoProfesor = !modoProfesor;
  if ((key == 'r' || key == 'R') && estadoJuego == 5) {
    reiniciarNave();
    estadoJuego = 3; // vuelve al pizarrón, mismo objetivo (y buffers), a intentar de nuevo
  }
  if (key == 'm' || key == 'M') reiniciarNivel(0);
}

void mouseDragged() { if (estadoJuego != 0) { camX += (mouseX - pmouseX) * SENSIBILIDAD_ARRASTRE; camY += (mouseY - pmouseY) * SENSIBILIDAD_ARRASTRE; } }
void mouseWheel(MouseEvent event) { if (estadoJuego != 0) zoom -= event.getCount() * SENSIBILIDAD_ZOOM; }

void dibujarOrbitas() {
  noFill(); strokeWeight(1); stroke(150, 150, 200, 45);
  for (Planeta p : planetas) {
    if (p.radioOrbita <= 0) continue;
    Vector3D centro = (p.padreOrbital != null) ? p.padreOrbital.posicion : new Vector3D(0, 0, 0);
    beginShape();
    for (float a = 0; a < TWO_PI; a += 0.1) {
      float xOrb = p.radioOrbita * cos(a);
      float yOrb = p.radioOrbita * sin(a);
      vertex(centro.x + xOrb, centro.y + yOrb * cos(p.inclinacionRad), centro.z + yOrb * sin(p.inclinacionRad));
    }
    endShape(CLOSE);
  }
}

void dibujarCampoVectorial() {
  int espaciado = 400; int limite = 4000;
  for (int x = -limite; x <= limite; x += espaciado) {
    for (int y = -limite; y <= limite; y += espaciado) {
      Vector3D puntoEspacio = new Vector3D(x, y, 0);
      Vector3D gTotal = new Vector3D(0, 0, 0);
      for (Planeta p : planetas) gTotal.sumar(p.calcularGravedadEnPunto(puntoEspacio));
      float largoVisual = min(gTotal.magnitud() * 4000, espaciado - 40);
      if (largoVisual > 5) {
        gTotal.normalizar();
        pushMatrix(); translate(x, y, 0);
        stroke(255, 255, 255, 70); strokeWeight(1);
        line(0, 0, 0, gTotal.x * largoVisual, gTotal.y * largoVisual, 0);
        translate(gTotal.x * largoVisual, gTotal.y * largoVisual, 0);
        rotateZ(atan2(gTotal.y, gTotal.x));
        fill(255, 255, 255, 70); noStroke(); triangle(0, 0, -6, 3, -6, -3);
        popMatrix();
      }
    }
  }
}

void dibujarPlanoCartesiano() {
  pushMatrix();
  int limite = int(LIMITE_MUNDO); int espaciado = 200;
  stroke(255, 255, 255, 20); strokeWeight(1);
  for (int i = -limite; i <= limite; i += espaciado) {
    line(i, -limite, 0, i, limite, 0); line(-limite, i, 0, limite, i, 0);
  }
  stroke(255, 50, 50, 200); strokeWeight(3); line(-limite, 0, 0, limite, 0, 0);
  stroke(50, 255, 50, 200); strokeWeight(3); line(0, -limite, 0, 0, limite, 0);
  fill(255); noStroke(); ellipse(0, 0, 10, 10);
  popMatrix();
}
