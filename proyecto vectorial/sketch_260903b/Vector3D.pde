/*
 * ============================================================
 *  CLASE Vector3D
 *  TEMA 1.1 — Definición de un vector en el plano y en el espacio
 *  ------------------------------------------------------------
 *  Un vector en R³ se representa con tres componentes (x, y, z),
 *  que son sus proyecciones sobre los ejes i, j, k.
 *  Cuando z = 0, el vector vive "en el plano" (R²);
 *  cuando z != 0, vive "en el espacio" (R³).
 *  Esta clase es la base matemática de TODO el proyecto: la
 *  posición, la velocidad, la aceleración y cada fuerza que
 *  actúa sobre la nave son, en el fondo, objetos Vector3D.
 * ============================================================
 */
class Vector3D {
  float x, y, z;

  Vector3D(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  // ---------- TEMA 1.2 — Álgebra vectorial y su geometría ----------
  // Suma geométrica: mueve la punta de un vector al final del otro
  // (regla del paralelogramo / punta-cola).
  void sumar(Vector3D v) {
    this.x += v.x;
    this.y += v.y;
    this.z += v.z;
  }

  // Resta vectorial: A - B = A + (-B). Geométricamente, es el
  // vector que va DESDE la punta de B HASTA la punta de A.
  void restar(Vector3D v) {
    this.x -= v.x;
    this.y -= v.y;
    this.z -= v.z;
  }

  // Multiplicación por escalar: estira (|k|>1), encoge (|k|<1)
  // o invierte el sentido (k<0) del vector, sin cambiar su dirección.
  void multiplicar(float escalar) {
    this.x *= escalar;
    this.y *= escalar;
    this.z *= escalar;
  }

  // Magnitud (norma): longitud del vector, teorema de Pitágoras en 3D.
  // ||v|| = raiz(x^2 + y^2 + z^2)
  float magnitud() {
    return sqrt(x*x + y*y + z*z);
  }

  // Normalización: produce un vector unitario (magnitud = 1) que
  // conserva la dirección original. Se usa para separar
  // "dirección" de "magnitud" — clave para aplicar fuerzas (1.6).
  void normalizar() {
    float m = magnitud();
    if (m != 0) {
      x /= m;
      y /= m;
      z /= m;
    }
  }

  // Vector que va de "otroPunto" hacia "this" (resta de puntos).
  // Es la herramienta base para calcular distancias y direcciones
  // entre dos cuerpos (nave-planeta, nave-agujero negro, etc.).
  Vector3D calcularDistancia(Vector3D otroPunto) {
    return new Vector3D(this.x - otroPunto.x, this.y - otroPunto.y, this.z - otroPunto.z);
  }

  // ---------- TEMA 1.3 — Producto escalar y vectorial ----------

  // Producto Escalar (Punto): A.B = Ax*Bx + Ay*By + Az*Bz
  // Resultado: un número (float), no un vector.
  // Geométricamente: A.B = ||A||*||B||*cos(theta). Sirve para medir
  // qué tan "alineados" están dos vectores.
  float productoPunto(Vector3D v) {
    return (this.x * v.x) + (this.y * v.y) + (this.z * v.z);
  }

  // Producto Vectorial (Cruz): AxB = nuevo vector PERPENDICULAR
  // (a 90°) a A y a B simultáneamente.
  // Se usa aquí para hallar el vector normal al plano orbital
  // que forman la posición y la velocidad de la nave (ver 1.5).
  Vector3D productoCruz(Vector3D v) {
    float nuevoX = (this.y * v.z) - (this.z * v.y);
    float nuevoY = (this.z * v.x) - (this.x * v.z);
    float nuevoZ = (this.x * v.y) - (this.y * v.x);
    return new Vector3D(nuevoX, nuevoY, nuevoZ);
  }

  // APLICACIÓN (1.6) del producto punto: ángulo entre dos vectores.
  // cos(theta) = (A.B) / (||A||*||B||)  ->  theta = arccos(...)
  // Se usa para saber qué tan desviado está el rumbo de la nave
  // respecto a la dirección hacia un objetivo (p. ej. Marte).
  float anguloEntre(Vector3D v) {
    float magnitudes = this.magnitud() * v.magnitud();
    if (magnitudes == 0) return 0;
    float cosTheta = this.productoPunto(v) / magnitudes;
    // Evitar errores de redondeo de punto flotante que pasen de 1 o -1
    cosTheta = max(-1, min(1, cosTheta));
    return acos(cosTheta); // Retorna en radianes
  }
}
