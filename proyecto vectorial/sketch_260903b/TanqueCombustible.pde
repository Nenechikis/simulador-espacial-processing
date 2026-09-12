/*
 * ============================================================
 *  CLASE TanqueCombustible
 *  TEMA 1.1/1.6 — Aplicación de magnitud de un vector: dos
 *  objetos "chocan" cuando la distancia entre sus posiciones
 *  (la magnitud del vector que los separa) es menor a un radio
 *  de colisión.
 *  NOTA: esta clase todavía no se usa en el sketch principal;
 *  se conecta en la fase 3 (mapa/sistema solar más grande).
 * ============================================================
 */
class TanqueCombustible {
  Vector3D posicion;
  float cantidad; // Cuánta gasolina da
  boolean recolectado; // Para saber si ya lo agarramos y desaparecerlo

  TanqueCombustible(float x, float y, float z) {
    posicion = new Vector3D(x, y, z);
    cantidad = 30.0; // Da 30 litros
    recolectado = false;
  }

  // Matemáticas de Colisión
  void verificarColision(Nave nave) {
    if (!recolectado) {
      // 1. Vector que va de la nave al tanque
      Vector3D vectorDistancia = posicion.calcularDistancia(nave.posicion);
      
      // 2. Magnitud de ese vector (Distancia real en el espacio)
      float distancia = vectorDistancia.magnitud();
      
      // 3. Si la distancia es menor a 25 pixeles, consideramos que chocaron
      if (distancia < 25) {
        nave.combustible += cantidad;
        // Evitamos que el tanque de la nave pase del 100%
        if (nave.combustible > 100) nave.combustible = 100; 
        
        recolectado = true; // Lo marcamos como "comido"
      }
    }
  }

  void dibujar() {
    if (!recolectado) {
      pushMatrix();
      translate(posicion.x, posicion.y, posicion.z);
      
      // Hacemos que el tanque rote sobre sí mismo para que parezca flotando en el espacio
      // frameCount es una variable de Processing que cuenta los cuadros por segundo
      rotateX(frameCount * 0.03);
      rotateY(frameCount * 0.03);
      
      fill(50, 255, 50); // Verde neón tipo "Energía"
      noStroke();
      box(15); // Un cubito
      
      popMatrix();
    }
  }
}
