/* Alvaro Oliveira RGM: 11221103413 */

create table veterinarios (
    id_veterinario int primary key auto_increment,
    nome varchar(100) not null,
    especializacao varchar(100),
    telefone varchar(15),
    email varchar(100),
    crmv varchar(50) not null
);
create table medicamentos (
    id_medicamento int primary key auto_increment,
    nome varchar(100) not null,
    dosagem varchar(50),
    instrucoes_uso text,
    id_paciente int,
    id_consulta int,
    foreign key (id_paciente) references pacientes(id_paciente),
    foreign key (id_consulta) references consultas(id_consulta)
);
create table pagamentos (
    id_pagamento int primary key auto_increment,
    id_consulta int,
    valor decimal(10, 2),
    data_pagamento date,
    metodo_pagamento varchar(50),
    foreign key (id_consulta) references consultas(id_consulta)
);

/*trigger para consultar se a consulta foi paga */
delimiter //
create trigger atualizar_status_consulta
after insert on pagamentos
for each row
begin
    update consultas
    set status = 'paga'
    where id_consulta = new.id_consulta;
end //
delimiter ;
/*trigger para registrar pagamentos */
delimiter //
create trigger registrar_historico_pagamento
after insert on pagamentos
for each row
begin
    insert into historico_pagamentos (id_pagamento, valor, data_pagamento, metodo_pagamento)
    values (new.id_pagamento, new.valor, new.data_pagamento, new.metodo_pagamento);
end //
delimiter ;
/*trigger para recusar pagamentos inválidos */
delimiter //
create trigger log_tentativa_pagamento_invalida
before insert on pagamentos
for each row
begin
    if new.valor <= 0 then
        insert into log_pagamentos_invalidos (valor_tentativa, data_tentativa)
        values (new.valor, now());
    end if;
end //
delimiter ;
/*trigger para recusar agendamentos duplicados */
delimiter //
create trigger verificar_agendamento_duplicado
before insert on agendamentos
for each row
begin
    if exists (select 1 from agendamentos 
               where data = new.data and hora = new.hora 
               and id_paciente = new.id_paciente 
               and id_veterinario = new.id_veterinario) then
        signal sqlstate '45000'
        set message_text = 'Já existe um agendamento para este paciente e veterinário neste horário';
    end if;
end //
delimiter ;
/*trigger para conferir se o nome do paciente tem conteúdo */
delimiter //
create trigger verificar_nome_paciente
before insert on paciente
for each row
begin
    if new.nome = '' then
        signal sqlstate '45000'
        set message_text = 'O nome do paciente não pode ser vazio';
    end if;
end //
delimiter ;

/*procedure para registro de pagamento */
delimiter //
create procedure registrar_pagamento(
    in p_id_consulta int,
    in p_valor decimal(10, 2),
    in p_data_pagamento date,
    in p_metodo_pagamento varchar(50)
)
begin
    insert into pagamentos (id_consulta, valor, data_pagamento, metodo_pagamento)
    values (p_id_consulta, p_valor, p_data_pagamento, p_metodo_pagamento);
end //
delimiter ;
/*procedure para alterar método de pagamento */
delimiter //
create procedure atualizar_metodo_pagamento(
    in p_id_pagamento int,
    in p_novo_metodo varchar(50)
)
begin
    update pagamentos
    set metodo_pagamento = p_novo_metodo
    where id_pagamento = p_id_pagamento;
end //
delimiter ;
/*procedure para listar os pagamentos por cliente */
delimiter //
create procedure listar_pagamentos_por_paciente(
    in p_id_paciente int
)
begin
    select * from pagamentos
    where id_consulta in (select id_consulta from consultas where id_paciente = p_id_paciente);
end //
delimiter ;
/*procedure para cálculo de gasto total do cliente */
delimiter //
create procedure total_gasto_por_paciente(
    in p_id_paciente int,
    out p_total_gasto decimal(10, 2)
)
begin
    select ifnull(sum(valor), 0) into p_total_gasto
    from pagamentos
    where id_consulta in (select id_consulta from consultas where id_paciente = p_id_paciente);
end //
delimiter ;
/*procedure para atualizar dados do veterinario */
delimiter //
create procedure atualizar_veterinario(
    in p_id_veterinario int,
    in p_novo_nome varchar(100),
    in p_nova_especialidade varchar(50)
)
begin
    update veterinarios
    set nome = p_novo_nome,
        especialidade = p_nova_especialidade
    where id_veterinario = p_id_veterinario;
end //
delimiter ;