CREATE TABLE public.categoria (
    id SERIAL PRIMARY KEY,
    nome VARCHAR NOT NULL
);

CREATE TABLE public.despesas (
    id SERIAL PRIMARY KEY,
    id_login INTEGER NOT NULL,
    descricao VARCHAR NOT NULL,
    valor NUMERIC(10, 2) NOT NULL,
    data_vencimento DATE NOT NULL,
    recorrencia BOOLEAN NOT NULL,
    fim_recorrencia DATE,
    id_categoria INTEGER NOT NULL,
    CONSTRAINT fk_receitas_usuario FOREIGN KEY (id_login) REFERENCES public.login(id),
    CONSTRAINT fk_categoria FOREIGN KEY (id_categoria) REFERENCES public.categoria(id)
);

INSERT INTO public.categoria (nome) VALUES
('Mercado'),
('Cartão de Crédito'),
('Gasolina'),
('Aluguel'),
('Transporte'),
('Educação'),
('Saúde'),
('Lazer'),
('Assinaturas'),
('Restaurantes'),
('Internet'),
('Luz'),
('Água'),
('Celular');