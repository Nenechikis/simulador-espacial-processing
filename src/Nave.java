import java.util.ArrayList;
import processing.core.PApplet;
import static processing.core.PApplet.atan2;

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
public class Nave {
  PApplet app;
  Vector3D posicion;
  Vector3D velocidad;
  Vector3D aceleracion;
  Vector3D ultimaAceleracion; // Guarda r''(t) del cuadro actual para curvatura y Frenet (Tema 3)
  float masa;
  float combustible;
  boolean estaPropulsando;
  boolean viva = true;

  // Lista para guardar el rastro (trayectoria recorrida)
  ArrayList<Vector3D> rastro;

  public Nave(PApplet app, float x, float y, float z) {
    this.app = app;
    posicion = new Vector3D(x, y, z);
    velocidad = new Vector3D(0, 0, 0);
    aceleracion = new Vector3D(0, 0, 0);
    ultimaAceleracion = new Vector3D(0, 0, 0);
    masa = 1.0f;
    combustible = 100.0f;
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
    fuerzaAplicada.multiplicar(1.0f / masa);
    aceleracion.sumar(fuerzaAplicada);
  }

  // Empuje del jugador (motores). Ahora acepta las tres
  // componentes (x, y, z) para que la nave pueda moverse
  // realmente "en el espacio" (TEMA 1.1) y no solo en el plano.
  void propulsar(float fuerzaX, float fuerzaY, float fuerzaZ) {
    if (combustible > 0) {
      Vector3D impulso = new Vector3D(fuerzaX, fuerzaY, fuerzaZ);
      aplicarFuerza(impulso);
      combustible -= 0.1f;
      estaPropulsando = true;
    }
  }

  // TEMA 1.2 — Integración: velocidad += aceleración,
  // posición += velocidad (método de Euler). Cada cuadro,
  // la posición "camina" en la dirección del vector velocidad.
  void actualizar() {
    if (!viva) return; // Si ya no está viva, ignoramos la física y ya no se mueve

    ultimaAceleracion = aceleracion.copia();
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
    app.noFill();
    app.stroke(255, 255, 255, 80); // Blanco sutil y semitransparente
    app.strokeWeight(1.5f);
    app.beginShape(); // beginShape es ideal para conectar muchos puntos
    for (Vector3D p : rastro) {
      app.vertex(p.x, p.y, p.z);
    }
    app.endShape();

    // 2. Dibujamos la nave
    app.pushMatrix();
    app.translate(posicion.x, posicion.y, posicion.z);
    float angulo = atan2(velocidad.y, velocidad.x);
    app.rotateZ(angulo);
    app.noStroke();

    app.fill(180, 180, 190);
    app.box(30, 8, 8);

    app.pushMatrix();
    app.translate(5, 0, 4);
    app.fill(50, 200, 255);
    app.box(10, 6, 4);
    app.popMatrix();

    app.pushMatrix();
    app.translate(-5, 0, 0);
    app.fill(100, 100, 110);
    app.box(15, 30, 2);
    app.popMatrix();

    if (estaPropulsando && combustible > 0) {
      app.pushMatrix();
      app.translate(-20, 0, 0);
      app.fill(255, 100, 0);
      app.box(10, 6, 6);
      app.popMatrix();
    }
    app.popMatrix();
  }

  // TEMA 1.1 (interpretación geométrica) + 1.6 (aplicación) + TEMA 3 (Marco de Frenet):
  // dibuja el vector velocidad (verde), el vector fuerza neta
  // (amarillo) y la binormal / normal al plano orbital B = T x N (magenta)
  // como flechas 3D ancladas en la nave, para que se
  // "vea" lo que normalmente solo son números.
  void dibujarVectores(Vector3D fuerzaActual) {
    app.pushMatrix();
    app.translate(posicion.x, posicion.y, posicion.z);

    // Escalas MÁS GRANDES que antes: con el mapa del sistema solar
    // completo, los vectores a escala real quedan invisibles.
    dibujarFlecha(velocidad.x * 40, velocidad.y * 40, velocidad.z * 40, app.color(0, 255, 0));
    dibujarFlecha(fuerzaActual.x * 600, fuerzaActual.y * 600, fuerzaActual.z * 600, app.color(255, 255, 0));

    // Vector Normal al plano orbital / Binormal (N = r x v), en magenta (Cap. 6.5 y 11.6)
    Vector3D normalOrb = posicion.productoCruz(velocidad);
    if (normalOrb.magnitud() > 0.001f) {
      normalOrb.normalizar();
      dibujarFlecha(normalOrb.x * 95, normalOrb.y * 95, normalOrb.z * 95, app.color(255, 80, 255));
    }

    app.popMatrix();
  }

  void dibujarFlecha(float vx, float vy, float vz, int colorFlecha) {
    app.stroke(colorFlecha);
    app.strokeWeight(4);
    app.line(0, 0, 0, vx, vy, vz);
    app.pushMatrix();
    app.translate(vx, vy, vz);
    float angulo = atan2(vy, vx);
    app.rotateZ(angulo);
    app.fill(colorFlecha);
    app.noStroke();
    app.triangle(0, 0, -16, 8, -16, -8);
    app.popMatrix();
  }
}
