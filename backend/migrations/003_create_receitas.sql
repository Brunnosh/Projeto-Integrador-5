CREATE TABLE public.tipo_despesa_receita (
    id SERIAL PRIMARY KEY,
    tipo VARCHAR NOT NULL
);

CREATE TABLE public.receitas (
    id SERIAL PRIMARY KEY,
    id_login INTEGER NOT NULL,
    descricao VARCHAR NOT NULL,
    valor NUMERIC(10, 2) NOT NULL,
    data_recebimento DATE NOT NULL,
    id_tipo INTEGER NOT NULL,
    CONSTRAINT fk_receitas_usuario FOREIGN KEY (id_login) REFERENCES public.login(id),
    CONSTRAINT fk_receitas_tipo FOREIGN KEY (id_tipo) REFERENCES public.tipo_despesa_receita(id)
);

INSERT INTO public.tipo_despesa_receita (tipo) VALUES
('Fixo'),
('Variável');