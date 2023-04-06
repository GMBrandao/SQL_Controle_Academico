create database Controle_Academico;
GO
USE Controle_Academico;
GO

create table Aluno(
    RA varchar(15) NOT NULL,
    nomeAluno varchar(50) NOT NULL,

    constraint PK_Aluno PRIMARY KEY (RA)
);
GO

create table Matricula(
    ID int NOT NULL identity(1,1),
    ra_Aluno varchar(15) NOT NULL,
    ano int NOT NULL,
    semestre int NOT NULL,

    constraint PK_Matricula PRIMARY KEY (ID),
    constraint FK_Matricula_Aluno FOREIGN KEY (ra_Aluno) REFERENCES Aluno(RA),
    constraint UN_Matricula UNIQUE (ra_Aluno, ano, semestre)
);
GO

create table Disciplina(
    CODIGO int NOT NULL identity(1,1),
    nomeDisciplina varchar(30) NOT NULL,
    carga_horaria int NOT NULL

    constraint PK_Disciplina PRIMARY KEY (CODIGO)
);
GO

create table Item_Matricula(
    ID_Mat int NOT NULL,
    COD_Disc int NOT NULL,
    nota1 decimal(4,2),
    nota2 decimal(4,2),
    sub decimal(4,2),
    faltas int NOT NULL,
    situacao varchar(19) NOT NULL,

    constraint FK_Item_Matricula_Matricula FOREIGN KEY (ID_Mat) REFERENCES Matricula(ID),
    constraint FK_Item_Matricula_Disciplina FOREIGN KEY (COD_Disc) REFERENCES Disciplina(CODIGO),
    constraint PK_Item_Matricula PRIMARY KEY (ID_Mat, COD_Disc)
);
GO

insert into Aluno values ('1', 'Giovani');
insert into Aluno (nomeAluno, ra) values ('Ana Maria', '2');
insert into Aluno values ('3', 'Felipe');

select * from Aluno order by (nomeAluno);

insert into Disciplina values ('Banco de Dados', 80), ('IA', 80), ('SO', 60);
update Disciplina set nomeDisciplina = 'Inteligência Artificial', carga_horaria = 100 where CODIGO = 2;
select * from Disciplina;

insert into Matricula values ('2', 2023, 1);
insert into Matricula values ('1', 2023, 1), ('3', 2023, 1);
select * from Matricula order by ID;

insert into Item_Matricula (ID_Mat, COD_Disc, faltas, situacao) values (1, 2, 0, 'Matriculado'),  (1, 1, 0, 'Matriculado'), (1, 3, 0, 'Matriculado');
insert into Item_Matricula (ID_Mat, COD_Disc, faltas, situacao) values (2, 2, 0, 'Matriculado'),  (2, 1, 0, 'Matriculado');
select * from Item_Matricula;

select m.ano, m.semestre, a.nomeAluno, d.nomeDisciplina 
    from Aluno a join Matricula m on a.ra = m.ra_Aluno
    join Item_Matricula im on m.id = im.ID_Mat
    join Disciplina d on im.COD_Disc = d.CODIGO;
GO

select m.ano, m.semestre, m.id, a.nomeAluno, d.nomeDisciplina, im.nota1, im.nota2, im.sub, im.faltas, im.situacao
    from Aluno a join Matricula m on a.ra = m.ra_Aluno
    join Item_Matricula im on m.id = im.ID_Mat
    join Disciplina d on im.COD_Disc = d.CODIGO;
GO


select m.ano, m.semestre, m.id as 'Matricula', a.nomeAluno, d.nomeDisciplina, im.nota1, im.nota2, im.sub,
    case
            when(sub is null) then (nota1+nota2)/2
            when(sub > nota1) and (nota1 < nota2) then (sub+nota2)/2
            when(sub > nota2) and (nota2 < nota1) then (sub+nota1)/2
    end as 'Media'
    from Aluno a join Matricula m on a.ra = m.ra_Aluno
    join Item_Matricula im on m.ID = im.ID_Mat
    join Disciplina d on im.COD_Disc = d.CODIGO
    where a.nomeAluno = 'Ana Maria';
GO

ALTER table Item_Matricula ADD
    media DECIMAL(4,2)
GO

CREATE OR ALTER TRIGGER TGR_Media_Insert ON Item_Matricula AFTER UPDATE
AS
BEGIN
    IF(UPDATE(nota2))
    BEGIN
        DECLARE @id int, @codigo int,  @nota1 decimal(4,2), @nota2 decimal (4,2), @media DECIMAL(4,2)

        SELECT @id = ID_Mat, @codigo = COD_Disc, @nota1 = nota1, @nota2 = nota2 from inserted

        SET @media = (@nota1 + @nota2) / 2
        UPDATE Item_Matricula SET media = @media WHERE ID_Mat = @id AND COD_Disc = @codigo
    END
END
GO

CREATE OR ALTER TRIGGER TGR_Situacao_Update ON Item_Matricula AFTER UPDATE
AS
BEGIN
    IF(UPDATE(media))
    BEGIN
        DECLARE @id int, @codigo int, @media DECIMAL(4,2), @situacao varchar(19)

        SELECT @id = ID_Mat, @codigo = COD_Disc, @situacao = situacao from inserted
        select @media =  media from Item_Matricula where @id = ID_Mat AND @codigo = COD_Disc


        SET @situacao = CASE
            WHEN (@media > 5) THEN
                'Aprovado'
            ELSE
                'Reprovado'
        END

        UPDATE Item_Matricula SET situacao = @situacao where ID_Mat = @id AND COD_Disc = @codigo
    END
END
GO

CREATE OR ALTER TRIGGER TGR_Situacao_Faltas ON Item_Matricula AFTER UPDATE
AS
BEGIN
    IF(UPDATE(faltas))
    BEGIN
        DECLARE @id int, @codigo int, @situacao varchar(19), @faltas int, @carga_horaria int
        SELECT @id = ID_Mat, @codigo = COD_Disc, @faltas = faltas from inserted
        Select @carga_horaria = carga_horaria from Disciplina where @codigo = CODIGO
        SELECT @situacao = im.situacao from Item_Matricula im where @codigo = COD_Disc and @id = ID_Mat
        --PRINT(@situacao)
        --SELECT @id = ID_Mat, @codigo = COD_Disc, @carga_horaria = d.carga_horaria from inserted join Disciplina d where @codigo = Codigo

        SET @situacao = CASE
            WHEN( @faltas > (@carga_horaria/2)) THEN
                'Reprovado por FALTA'
            ELSE
                @situacao            
        END
        UPDATE Item_Matricula SET situacao = @situacao where ID_Mat = @id AND COD_Disc = @codigo
    END
END
GO

CREATE OR ALTER PROCEDURE CalculaMedia @ID INT, @CODIGO INT
AS
BEGIN
    DECLARE @nota1 decimal(4,2), @nota2 decimal(4,2), @media decimal(4,2)

    SELECT @nota1 = nota1, @nota2 = nota2 FROM Item_Matricula WHERE @id = ID_Mat AND @codigo = COD_Disc

    SET @media = (@nota1+ @nota2) / 2

    UPDATE Item_matricula SET media = @media WHERE @id = ID_Mat AND @codigo = COD_Disc

END;
GO

EXEC.Calculamedia 1,1

UPDATE Item_Matricula SET nota1 = 7.5, nota2 = 5.7 WHERE ID_Mat = 3 AND COD_Disc = 2;
UPDATE Item_Matricula SET nota1 = 6.9, nota2 = 4.3 WHERE ID_Mat = 3 AND COD_Disc = 1;
update Item_Matricula set nota1 = 6, nota2 = 3 where COD_Disc = 2 and ID_Mat = 1;
update Item_Matricula set nota1 = 6, nota2 = 6.4 where COD_Disc = 1 and ID_Mat = 1;

UPDATE Item_Matricula SET faltas = 56 WHERE ID_Mat = 3 AND COD_Disc = 1;
UPDATE Item_Matricula SET faltas = 40 WHERE ID_Mat = 1 AND COD_Disc = 1;
UPDATE Item_Matricula SET nota1 = 6, nota2 = 8 WHERE ID_Mat = 2 AND COD_Disc = 1;
GO

select * from Item_Matricula
GO

CREATE OR ALTER PROCEDURE IniciarSemestre
AS
BEGIN
    UPDATE Item_Matricula SET 
        media = null, nota1 = null,
        nota2 = null, situacao = 'Matriculado',
        faltas = 0, sub = null
END;
GO

EXEC.IniciarSemestre
GO

CREATE OR ALTER PROCEDURE MatricularAlunoEmMateria @id_Mat INT, @codigo_Disc INT
AS
BEGIN
    DECLARE @idConfirm INT
    select @idConfirm = ID FROM Matricula WHERE ID = @id_Mat

    if(@idConfirm is not null)
    BEGIN
        INSERT INTO Item_Matricula (ID_Mat, COD_Disc, situacao, faltas) values (
            @id_Mat, @codigo_Disc, 'Matriculado', 0
        )
        PRINT('Aluno matriculado com sucesso')
    END
    ELSE
    BEGIN
        PRINT('Não existe o aluno matriculado')
    END

END;
GO

EXEC.MatricularAlunoEmMateria 3,3
EXEC.MatricularAlunoEmMateria 5,3
GO

CREATE OR ALTER PROCEDURE CriarAluno @ra varchar(15), @nomeAluno varchar(50)
AS
BEGIN
    
    INSERT INTO Aluno values (@ra, @nomeAluno)

END;
GO
EXEC.CriarAluno '7','Pestana'
GO

CREATE OR ALTER PROCEDURE MatricularAluno @raAluno varchar(15), @ano int, @semestre int
AS
BEGIN
    DECLARE @raConfirm INT
    select @raConfirm = ra FROM Aluno WHERE ra = @raAluno

    if(@raConfirm is not null)
    BEGIN
        INSERT INTO Matricula values (@raAluno, @ano, @semestre)
        PRINT('Aluno matriculado com sucesso')
    END
    ELSE
    BEGIN
        PRINT('Não existe o aluno matriculado')
    END

END;
GO
EXEC.MatricularAluno '7', 2020, 3
GO