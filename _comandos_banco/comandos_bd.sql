CREATE TABLE public.login (
	id serial NOT NULL,
	email varchar NOT NULL,
	senha varchar NOT NULL,
	CONSTRAINT login_unique UNIQUE (email)
);

CREATE TABLE public.dados_usuarios (
	id serial NOT NULL,
	id_login integer NOT NULL,
	nome varchar NOT NULL,
	sobrenome varchar NOT NULL,
	data_nascimento varchar NOT NULL,
	id_endereco integer NOT NULL,
	CONSTRAINT dados_usuarios_unique UNIQUE (id_login)
);

CREATE TABLE public.estados (
	id serial NOT NULL,
	nome varchar NOT NULL,
	sigla varchar NOT NULL
);

CREATE TABLE public.endereco (
	id serial NOT NULL,
	cep varchar NOT NULL,
	id_estado integer NOT NULL,
	bairro varchar NOT NULL,
	rua varchar NOT NULL,
	numero varchar NOT NULL,
	complemento varchar NOT NULL
);
