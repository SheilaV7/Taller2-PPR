% Parámetros
int: num_plantas;
int: num_dias;
int: num_clientes;

array[1..num_plantas] of int: coste_produccion;
array[1..num_plantas] of int: capacidad_maxima;
array[1..num_clientes, 1..num_dias] of int: demanda_diaria;

int: porcentaje_minimo;
array[1..num_clientes] of int: pago_por_mw;
array[1..num_plantas] of int: porcentaje_regimen_alto;
array[1..num_plantas] of int: max_dias_regimen_alto;

% Cálculo de demanda mínima
array[1..num_clientes, 1..num_dias] of int: demanda_minima =
  array2d(1..num_clientes, 1..num_dias, [ (demanda_diaria[c,d] * porcentaje_minimo) div 100 | c in 1..num_clientes, d in 1..num_dias ]);
  
% Variables
array[1..num_plantas, 1..num_dias] of var int: produccion_diaria;
array[1..num_clientes, 1..num_dias] of var int: energia_entregada;

% Restricciones

% Limitando dominio de producción diaria
constraint forall(p in 1..num_plantas, d in 1..num_dias) (
  produccion_diaria[p,d] >= 0 /\ produccion_diaria[p,d] <= capacidad_maxima[p]);

% Limitando dominio de energía entregada
constraint forall(c in 1..num_clientes, d in 1..num_dias) (
  energia_entregada[c,d] >= demanda_minima[c,d] /\ energia_entregada[c,d] <= demanda_diaria[c,d]);

% Producción diaria = Energía entregada
constraint forall(d in 1..num_dias) (
  sum(p in 1..num_plantas)(produccion_diaria[p,d]) = sum(c in 1..num_clientes)(energia_entregada[c,d]));

% Restricción de régimen alto
constraint forall(p in 1..num_plantas, d in 1..num_dias-1) (
  not (
    produccion_diaria[p,d] > (porcentaje_regimen_alto[p] * capacidad_maxima[p]) div 100 /\
    produccion_diaria[p,d+1] > (porcentaje_regimen_alto[p] * capacidad_maxima[p]) div 100
));


% Restricciones redundantes
constraint 
  sum(c in 1..num_clientes, d in 1..num_dias)(energia_entregada[c,d]) >= 
  sum(c in 1..num_clientes, d in 1..num_dias)(demanda_minima[c,d]);

constraint forall(c in 1..num_clientes)(
  sum(d in 1..num_dias)(energia_entregada[c,d]) >= sum(d in 1..num_dias)(demanda_minima[c,d]) /\
  sum(d in 1..num_dias)(energia_entregada[c,d]) <= sum(d in 1..num_dias)(demanda_diaria[c,d]));

constraint forall(d in 1..num_dias)(
  sum(p in 1..num_plantas)(produccion_diaria[p,d]) >= sum(c in 1..num_clientes)(demanda_minima[c,d])
/\ sum(p in 1..num_plantas)(produccion_diaria[p,d]) <= sum(c in 1..num_clientes)(demanda_diaria[c,d]));

% Rompimiento de simetrías
constraint forall(p in 1..num_plantas-1, d in 1..num_dias)(
  produccion_diaria[p,d] >= produccion_diaria[p+1,d]);

constraint forall(p in 1..num_plantas-1)(
  sum(d in 1..num_dias)(produccion_diaria[p,d]) >= sum(d in 1..num_dias)(produccion_diaria[p+1,d]));

% Objetivo
var int: ganancia_neta = 
  sum(c in 1..num_clientes, d in 1..num_dias)(energia_entregada[c,d] * pago_por_mw[c]) -
  sum(p in 1..num_plantas, d in 1..num_dias)(produccion_diaria[p,d] * coste_produccion[p]);
  
% Solo valores positivos
constraint ganancia_neta >= 0;

% solve :: seq_search([
%   int_search([energia_entregada[c,d] | c in 1..num_clientes, d in 1..num_dias], first_fail, indomain_max, complete),
%   int_search([produccion_diaria[p,d] | p in 1..num_plantas, d in 1..num_dias], first_fail, indomain_max, complete),
% ]) maximize ganancia_neta;

% Mejor estrategia de búsqueda
solve :: seq_search([
  int_search([energia_entregada[c,d] | c in 1..num_clientes, d in 1..num_dias], first_fail, indomain_split, complete),
  int_search([produccion_diaria[p,d] | p in 1..num_plantas, d in 1..num_dias], first_fail, indomain_split, complete),
]) maximize ganancia_neta;

% solve :: seq_search([
%   int_search([energia_entregada[c,d] | c in 1..num_clientes, d in 1..num_dias], dom_w_deg, indomain_split, complete),
%   int_search([produccion_diaria[p,d] | p in 1..num_plantas, d in 1..num_dias], dom_w_deg, indomain_split, complete),
% ]) maximize ganancia_neta;

% Salida
output ["Ganancia neta: \(ganancia_neta)\n"] ++
       ["Producción planta \(p), día \(d): \(produccion_diaria[p,d])\n" | p in 1..num_plantas, d in 1..num_dias] ++
       ["Entrega cliente \(c), día \(d): \(energia_entregada[c,d])\n" | c in 1..num_clientes, d in 1..num_dias];
