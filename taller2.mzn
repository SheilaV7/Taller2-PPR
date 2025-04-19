% Parámetros
int: num_plantas;
int: num_dias;
int: num_clientes;

array[1..num_plantas] of float: coste_produccion;
array[1..num_plantas, 1..num_dias] of int: capacidad_maxima;
array[1..num_clientes, 1..num_dias] of int: demanda_diaria;

int: porcentaje_minimo;
array[1..num_clientes] of float: pago_por_mw;
array[1..num_plantas] of int: porcentaje_regimen_alto;
array[1..num_plantas] of int: max_dias_regimen_alto;

% Cálculo de demanda mínima
array[1..num_clientes, 1..num_dias] of int: demanda_minima =
  array2d(1..num_clientes, 1..num_dias, [ (demanda_diaria[c,d] * porcentaje_minimo) div 100 | c in 1..num_clientes, d in 1..num_dias ]);

% Variables
array[1..num_plantas, 1..num_dias] of var int: produccion_diaria;
array[1..num_clientes, 1..num_dias] of var int: energia_entregada;

% Restricciones
constraint forall(p in 1..num_plantas, d in 1..num_dias) (
  produccion_diaria[p,d] >= 0 /\ produccion_diaria[p,d] <= capacidad_maxima[p,d]
);

constraint forall(c in 1..num_clientes, d in 1..num_dias) (
  energia_entregada[c,d] >= demanda_minima[c,d] /\ energia_entregada[c,d] <= demanda_diaria[c,d]
);

constraint forall(d in 1..num_dias) (
  sum(p in 1..num_plantas)(produccion_diaria[p,d]) = sum(c in 1..num_clientes)(energia_entregada[c,d])
);

% Restricción de régimen alto
constraint forall(p in 1..num_plantas where max_dias_regimen_alto[p] > 0) (
  forall(d in 1..num_dias - max_dias_regimen_alto[p] + 1) (
    sum(i in 0..max_dias_regimen_alto[p]-1) (
      produccion_diaria[p, d+i] > (porcentaje_regimen_alto[p] * capacidad_maxima[p, d+i]) div 100
    ) < max_dias_regimen_alto[p]
  )
);

% Objetivo
var float: ganancia_neta = 
  sum(c in 1..num_clientes, d in 1..num_dias)(energia_entregada[c,d] * pago_por_mw[c]) -
  sum(p in 1..num_plantas, d in 1..num_dias)(produccion_diaria[p,d] * coste_produccion[p]);

solve maximize ganancia_neta;

% Salida
output ["Ganancia neta: \(ganancia_neta)\n"] ++
       ["Producción planta \(p), día \(d): \(produccion_diaria[p,d])\n" | p in 1..num_plantas, d in 1..num_dias] ++
       ["Entrega cliente \(c), día \(d): \(energia_entregada[c,d])\n" | c in 1..num_clientes, d in 1..num_dias];
