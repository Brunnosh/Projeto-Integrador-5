CREATE TABLE public.login (
    id serial PRIMARY KEY,
    email varchar NOT NULL,
    senha varchar NOT NULL,
    CONSTRAINT login_unique UNIQUE (email)
);

CREATE TABLE public.estados (
    id serial PRIMARY KEY,
    nome varchar NOT NULL,
    sigla varchar NOT NULL
);

CREATE TABLE public.endereco (
    id serial PRIMARY KEY,
    cep varchar NOT NULL,
    id_estado integer NOT NULL,
    bairro varchar NOT NULL,
    rua varchar NOT NULL,
    numero varchar NOT NULL,
    complemento varchar NOT NULL,
    CONSTRAINT fk_endereco_estado FOREIGN KEY (id_estado) REFERENCES public.estados(id)
);

CREATE TABLE public.dados_usuarios (
    id serial PRIMARY KEY,
    id_login integer NOT NULL,
    nome varchar NOT NULL,
    sobrenome varchar NOT NULL,
    data_nascimento varchar NOT NULL,
    id_endereco integer NOT NULL,
    CONSTRAINT dados_usuarios_unique UNIQUE (id_login),
    CONSTRAINT fk_dados_usuarios_login FOREIGN KEY (id_login) REFERENCES public.login(id),
    CONSTRAINT fk_dados_usuarios_endereco FOREIGN KEY (id_endereco) REFERENCES public.endereco(id)
);