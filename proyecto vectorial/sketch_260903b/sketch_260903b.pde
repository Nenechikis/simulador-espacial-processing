/*
 * ============================================================
 *  SIMULADOR VECTORIAL ESPACIAL
 *  Proyecto de Cálculo Vectorial — cubre los temas 1.1 a 1.6
 *
 *  MAPA DE TEMAS -> ARCHIVO:
 *   1.1 Vector en el plano y el espacio  -> Vector3D.pde, Planeta.pde (órbitas)
 *   1.2 Álgebra vectorial y su geometría -> Vector3D.pde, Nave.pde
 *   1.3 Producto escalar y vectorial     -> Vector3D.pde (usado aquí, TELEMETRÍA)
 *   1.4 Ecuación de la recta             -> este archivo (telemetría)
 *   1.5 Ecuación del plano               -> este archivo (telemetría)
 *   1.6 Aplicaciones                     -> Planeta.pde, TanqueCombustible.pde
 *
 *  ESTADOS (estadoJuego): 0 Menú | 1 Vuelo Libre | 2 Pizarrón | 3 Simulación
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
 *  ESCALA: usamos tamaños y distancias A ESCALA COMPRIMIDA
 *  (raíz cuadrada de los valores reales), no astronómica exacta.
 *  A escala real el Sol sería ~100 veces más grande que la Tierra
 *  y Neptuno estaría 77 veces más lejos que Mercurio — literalmente
 *  no cabría en un videojuego. La compresión conserva el ORDEN y
 *  las proporciones relativas correctas (el Sol es el más grande,
 *  los gigantes gaseosos le siguen, los rocosos son los más chicos)
 *  sin volver el mapa injugable. Esto es una decisión de diseño
 *  común en simuladores y vale la pena explicarla en la presentación.
 * ============================================================
 */
Nave miNave;
ArrayList<Planeta> planetas; // Sol + los 8 planetas + la Luna, en orden real
Planeta sol, mercurio, venus, tierra, luna, marte, jupiter, saturno, urano, neptuno;
boolean modoProfesor = false;

int estadoJuego = 0; // 0 Menú, 1 Vuelo Libre, 2 Pizarrón, 3 Simulación
float inputVx = 0.0;
float inputVy = 0.0;

// TEMA 1.6: constante de gravitación del "universo" del juego, en UN
// solo lugar para poder tunear el feeling de vuelo fácilmente.
float G_GRAVEDAD = 45.0;

float LIMITE_MUNDO = 8500;

float[] estrellasX = new float[1200];
float[] estrellasY = new float[1200];
float[] estrellasZ = new float[1200];

float camX = 0;
float camY = 0;
float zoom = -2600;
float SENSIBILIDAD_ARRASTRE = 2.2; // qué tanto se mueve la vista al arrastrar el mouse
float SENSIBILIDAD_ZOOM = 220;     // qué tanto acerca/aleja cada "click" de la rueda

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
  // configurarOrbita(padre, radioOrbita, velocidadAngular, anguloInicial°, inclinación°)
  // Distancias más separadas y velocidades más lentas para volar con calma.
  planetas = new ArrayList<Planeta>();

  sol = new Planeta("Sol", 0, 0, 0, 260, 300, fotoSol); // fijo, no orbita
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
  luna.configurarOrbita(tierra, 150, 0.0080, 0, 5.0); // orbita la Tierra, no el Sol
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

  // La nave arranca justo "despegando" de la Tierra (dondequiera que
  // esté su órbita en este instante), no en un punto fijo del mapa.
  miNave = new Nave(tierra.posicion.x, tierra.posicion.y - 150, tierra.posicion.z);
  if (estadoJuego == 1) miNave.velocidad = new Vector3D(2.0, 0, 0);
  else miNave.velocidad = new Vector3D(0, 0, 0);

  inputVx = 0.0; inputVy = 0.0;
  camX = 0; camY = 0; zoom = -2600;
}

void draw() {
  background(5, 5, 12);

  // Las órbitas SOLO avanzan en el Menú (para lucirse) y en Vuelo Libre.
  // Se CONGELAN en Pizarrón/Simulación: el Reto de esta fase asume que
  // Marte no se mueve mientras calculas a mano (ver nota de cabecera).
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

  dibujarOrbitas(); // Líneas sutiles, siempre visibles (no solo en Modo Profesor)

  Vector3D fuerzaNeta = new Vector3D(0, 0, 0);
  if (estadoJuego == 1 || estadoJuego == 3) {
    for (Planeta p : planetas) fuerzaNeta.sumar(p.calcularAtraccion(miNave));
    if (miNave.viva) {
      miNave.aplicarFuerza(fuerzaNeta);
      miNave.actualizar();
    }
  }

  for (Planeta p : planetas) p.dibujar();
  if (estadoJuego != 0) miNave.dibujar();

  if (modoProfesor) {
    // Vector velocidad orbital de cada planeta (para que los vectores
    // "se vean" también fuera de la nave)
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
    text("Combustible: " + nf(max(0, miNave.combustible), 0, 1) + " L", 20, height - 20);
    verificarCondicionesFin();
  } else if (estadoJuego == 2) {
    dibujarPizarronCalculo();
  } else if (estadoJuego == 3) {
    fill(255); textSize(14);
    text("SIMULANDO TRAYECTORIA... | Recalcular: 'R' | Menú: 'M'", 20, 30);
    verificarCondicionesFin();
  }

  // TELEMETRÍA MODO PROFESOR (Cubre 1.3, 1.4 y 1.5 del Temario)
  if (modoProfesor && (estadoJuego == 1 || estadoJuego == 3)) {
    fill(0, 200, 255); textSize(14);
    text("====== TELEMETRÍA MATEMÁTICA AVANZADA ======", 20, 80);

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

    Vector3D vectorHaciaMarte = marte.posicion.calcularDistancia(miNave.posicion);
    float anguloGrados = degrees(miNave.velocidad.anguloEntre(vectorHaciaMarte));
    fill(150, 255, 100);
    text("1.3 Aplicación de Producto Punto (Ángulo de Desviación):", 20, 365);
    text("Ángulo Nave-Marte: " + nf(anguloGrados, 0, 2) + "° (0° es rumbo perfecto)", 30, 385);
  }
}

void dibujarMenuPrincipal() {
  fill(0, 0, 0, 170); noStroke();
  rect(0, height/2 - 160, width, 340);

  fill(0, 200, 255);
  textSize(34); textAlign(CENTER);
  text("SIMULADOR ESPACIAL DANIELITO FREE FIRE", width/2, height/2 - 100);
  fill(180); textSize(12);
  fill(255); textSize(20);
  text("1. MODO VUELO LIBRE", width/2, height/2 - 10);
  text("2. MODO RETO MATEMÁTICO", width/2, height/2 + 30);
  fill(150); textSize(13);
  text("Presiona 1 o 2 para empezar | 'ESPACIO' Visualizador de físicas ", width/2, height/2 + 90);
  textAlign(LEFT);
}

void dibujarPizarronCalculo() {
  fill(0, 0, 0, 220); rect(10, 10, 470, 280);
  fill(255, 200, 0); textSize(18); text("RETO 1: CINEMÁTICA VECTORIAL", 25, 40);
  fill(255); textSize(14);
  text("Calcula el vector Velocidad (V) para llegar a Marte en t = 400s", 25, 70);
  text("ignorando la curvatura gravitacional inicial.", 25, 90);
  fill(0, 255, 255); text("FÓRMULA:  V = ( Posición Final - Posición Inicial ) / t", 25, 125);
  fill(255);
  text("Vx = ( " + nf(marte.posicion.x, 0, 0) + " - " + nf(miNave.posicion.x, 0, 0) + " ) / 400 = ?", 25, 160);
  text("Vy = ( " + nf(marte.posicion.y, 0, 0) + " - " + nf(miNave.posicion.y, 0, 0) + " ) / 400 = ?", 25, 185);
  fill(50, 255, 50); textSize(16); text("RESULTADOS (Ajusta con las Flechas):", 25, 225);
  text("Vx: " + nf(inputVx, 0, 2) + " i", 25, 250); text("Vy: " + nf(inputVy, 0, 2) + " j", 150, 250);
  fill(255, 100, 100); textSize(14); text("ENTER: Iniciar Simulación | 'M': Menú", 25, 275);
}

void verificarCondicionesFin() {
  if (miNave.posicion.magnitud() > LIMITE_MUNDO && miNave.viva) {
    fill(255, 50, 50); textSize(32); textAlign(CENTER);
    text("¡PERDIDO EN EL ESPACIO!", width/2, height/2); textAlign(LEFT); miNave.viva = false;
  }
  if (marte.posicion.calcularDistancia(miNave.posicion).magnitud() < 60 && miNave.viva) {
    fill(50, 255, 50); textSize(32); textAlign(CENTER);
    text("¡CÁLCULO EXACTO! LLEGASTE A MARTE", width/2, height/2); textAlign(LEFT); miNave.viva = false; miNave.velocidad.multiplicar(0);
  }
}

void keyPressed() {
  if (estadoJuego == 0) {
    if (key == '1') reiniciarNivel(1);
    if (key == '2') reiniciarNivel(2);
  } else if (estadoJuego == 2) {
    if (key == CODED) {
      if (keyCode == RIGHT) inputVx += 0.5;
      if (keyCode == LEFT)  inputVx -= 0.5;
      if (keyCode == DOWN)  inputVy += 0.5;
      if (keyCode == UP)    inputVy -= 0.5;
    }
    if (key == ENTER || key == RETURN) {
      miNave.velocidad = new Vector3D(inputVx, inputVy, 0);
      estadoJuego = 3;
    }
  }
}

void keyReleased() {
  if (key == ' ') modoProfesor = !modoProfesor;
  if ((key == 'r' || key == 'R') && estadoJuego == 3) reiniciarNivel(2);
  if (key == 'm' || key == 'M') reiniciarNivel(0);
}

void mouseDragged() { if (estadoJuego != 0) { camX += (mouseX - pmouseX) * SENSIBILIDAD_ARRASTRE; camY += (mouseY - pmouseY) * SENSIBILIDAD_ARRASTRE; } }
void mouseWheel(MouseEvent event) { if (estadoJuego != 0) zoom -= event.getCount() * SENSIBILIDAD_ZOOM; }

// Líneas sutiles del camino orbital de cada planeta (TEMA 1.1: el
// "lugar geométrico" que traza la punta del vector posición r(t)).
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
