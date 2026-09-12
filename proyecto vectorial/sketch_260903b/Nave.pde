/*
 * ============================================================
 *  CLASE Nave
 *  Representa el objeto que el jugador controla. Su posición,
 *  velocidad y aceleración son vectores (TEMA 1.1) que se
 *  actualizan cada cuadro siguiendo la física de Newton
 *  (F = m·a), aplicando TEMA 1.2 (álgebra vectorial: suma de
 *  fuerzas, escalado por 1/masa) para moverse en el espacio.
 * ============================================================
 */
class Nave {
  Vector3D posicion;
  Vector3D velocidad;
  Vector3D aceleracion;
  float masa;
  float combustible;
  boolean estaPropulsando;
  boolean viva = true;

  // Lista para guardar el rastro (trayectoria recorrida)
  ArrayList<Vector3D> rastro;

  Nave(float x, float y, float z) {
    posicion = new Vector3D(x, y, z);
    velocidad = new Vector3D(0, 0, 0);
    aceleracion = new Vector3D(0, 0, 0);
    masa = 1.0;
    combustible = 100.0;
    estaPropulsando = false;
    rastro = new ArrayList<Vector3D>();
  }

  // TEMA 1.2 — Segunda Ley de Newton como álgebra vectorial:
  // a = F / m  →  aceleración += fuerza * (1/masa)
  // Aquí es donde se SUMAN todas las fuerzas (gravedad de cada
  // planeta + agujero negro + empuje del jugador) en un solo
  // vector de aceleración neta.
  void aplicarFuerza(Vector3D fuerza) {
    Vector3D fuerzaAplicada = new Vector3D(fuerza.x, fuerza.y, fuerza.z);
    fuerzaAplicada.multiplicar(1.0 / masa);
    aceleracion.sumar(fuerzaAplicada);
  }

  // Empuje del jugador (motores). Ahora acepta las tres
  // componentes (x, y, z) para que la nave pueda moverse
  // realmente "en el espacio" (TEMA 1.1) y no solo en el plano.
  void propulsar(float fuerzaX, float fuerzaY, float fuerzaZ) {
    if (combustible > 0) {
      Vector3D impulso = new Vector3D(fuerzaX, fuerzaY, fuerzaZ);
      aplicarFuerza(impulso);
      combustible -= 0.1;
      estaPropulsando = true;
    }
  }

  // TEMA 1.2 — Integración: velocidad += aceleración,
  // posición += velocidad (método de Euler). Cada cuadro,
  // la posición "camina" en la dirección del vector velocidad.
  void actualizar() {
    if (!viva) return; // Si ya no está viva, ignoramos la física y ya no se mueve

    velocidad.sumar(aceleracion);
    posicion.sumar(velocidad);
    aceleracion.multiplicar(0);

    rastro.add(new Vector3D(posicion.x, posicion.y, posicion.z));
    if (rastro.size() > 150) {
      rastro.remove(0);
    }
  }

  void dibujar() {
    // 1. Dibujamos el rastro en el espacio global
    noFill();
    stroke(255, 255, 255, 80); // Blanco sutil y semitransparente
    strokeWeight(1.5);
    beginShape(); // beginShape es ideal para conectar muchos puntos
    for (Vector3D p : rastro) {
      vertex(p.x, p.y, p.z);
    }
    endShape();

    // 2. Dibujamos la nave
    pushMatrix();
    translate(posicion.x, posicion.y, posicion.z);
    float angulo = atan2(velocidad.y, velocidad.x);
    rotateZ(angulo);
    noStroke();

    fill(180, 180, 190);
    box(30, 8, 8);

    pushMatrix();
    translate(5, 0, 4);
    fill(50, 200, 255);
    box(10, 6, 4);
    popMatrix();

    pushMatrix();
    translate(-5, 0, 0);
    fill(100, 100, 110);
    box(15, 30, 2);
    popMatrix();

    if (estaPropulsando && combustible > 0) {
      pushMatrix();
      translate(-20, 0, 0);
      fill(255, 100, 0);
      box(10, 6, 6);
      popMatrix();
    }
    popMatrix();
  }

  // TEMA 1.1 (interpretación geométrica) + 1.6 (aplicación):
  // dibuja el vector velocidad (verde) y el vector fuerza neta
  // (amarillo) como flechas 3D ancladas en la nave, para que se
  // "vea" lo que normalmente solo son números.
  void dibujarVectores(Vector3D fuerzaActual) {
    pushMatrix();
    translate(posicion.x, posicion.y, posicion.z);

    // Escalas MÁS GRANDES que antes: con el mapa del sistema solar
    // completo, los vectores a escala real quedan invisibles.
    dibujarFlecha(velocidad.x * 40, velocidad.y * 40, velocidad.z * 40, color(0, 255, 0));
    dibujarFlecha(fuerzaActual.x * 600, fuerzaActual.y * 600, fuerzaActual.z * 600, color(255, 255, 0));

    popMatrix();
  }

  void dibujarFlecha(float vx, float vy, float vz, int colorFlecha) {
    stroke(colorFlecha);
    strokeWeight(4);
    line(0, 0, 0, vx, vy, vz);
    pushMatrix();
    translate(vx, vy, vz);
    float angulo = atan2(vy, vx);
    rotateZ(angulo);
    fill(colorFlecha);
    noStroke();
    triangle(0, 0, -16, 8, -16, -8);
    popMatrix();
  }
}
