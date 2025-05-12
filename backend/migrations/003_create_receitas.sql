CREATE TABLE public.receitas (
    id SERIAL PRIMARY KEY,
    id_login INTEGER NOT NULL,
    descricao VARCHAR NOT NULL,
    valor NUMERIC(10, 2) NOT NULL,
    data_recebimento DATE NOT NULL,
    recorrencia BOOLEAN NOT NULL,
    CONSTRAINT fk_receitas_usuario FOREIGN KEY (id_login) REFERENCES public.login(id)
);