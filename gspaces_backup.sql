--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9
-- Dumped by pg_dump version 16.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cart; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.cart (
    id integer NOT NULL,
    user_id integer,
    product_id integer,
    quantity integer DEFAULT 1
);


ALTER TABLE public.cart OWNER TO sri;

--
-- Name: cart_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.cart_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cart_id_seq OWNER TO sri;

--
-- Name: cart_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.cart_id_seq OWNED BY public.cart.id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.order_items (
    id integer NOT NULL,
    order_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer NOT NULL,
    price_at_purchase numeric(10,2) NOT NULL,
    product_name character varying(255),
    image_url character varying(255)
);


ALTER TABLE public.order_items OWNER TO sri;

--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.order_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_items_id_seq OWNER TO sri;

--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.orders (
    id integer NOT NULL,
    user_id integer NOT NULL,
    order_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    total_amount numeric(10,2) NOT NULL,
    status character varying(50) DEFAULT 'Pending'::character varying,
    user_email character varying(255),
    razorpay_order_id character varying(255) NOT NULL,
    razorpay_payment_id character varying(255) NOT NULL
);


ALTER TABLE public.orders OWNER TO sri;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orders_id_seq OWNER TO sri;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: product_sub_images; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.product_sub_images (
    id integer NOT NULL,
    product_id integer NOT NULL,
    image_url text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.product_sub_images OWNER TO sri;

--
-- Name: product_sub_images_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.product_sub_images_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_sub_images_id_seq OWNER TO sri;

--
-- Name: product_sub_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.product_sub_images_id_seq OWNED BY public.product_sub_images.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.products (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    category text,
    price numeric,
    rating numeric,
    image_url text,
    created_by character varying(255),
    detailed_description text
);


ALTER TABLE public.products OWNER TO sri;

--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_id_seq OWNER TO sri;

--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.reviews (
    id integer NOT NULL,
    product_id integer NOT NULL,
    user_id integer,
    username character varying(255) NOT NULL,
    rating integer,
    comment text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.reviews OWNER TO sri;

--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reviews_id_seq OWNER TO sri;

--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    password text NOT NULL,
    address text,
    phone character varying(20)
);


ALTER TABLE public.users OWNER TO sri;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO sri;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: cart id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.cart ALTER COLUMN id SET DEFAULT nextval('public.cart_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: product_sub_images id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_sub_images ALTER COLUMN id SET DEFAULT nextval('public.product_sub_images_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: cart; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.cart (id, user_id, product_id, quantity) FROM stdin;
9	12	7	1
10	15	7	1
11	16	7	1
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.order_items (id, order_id, product_id, quantity, price_at_purchase, product_name, image_url) FROM stdin;
1	4	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
2	5	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
3	6	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
4	7	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
5	8	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
6	9	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
7	10	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png
8	11	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
9	12	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
10	13	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
11	14	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
12	15	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
13	16	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
14	17	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
15	18	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
16	19	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
17	20	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
18	21	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
19	22	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
20	23	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
21	24	9	1	1.00	Scandi Minimal	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.orders (id, user_id, order_date, total_amount, status, user_email, razorpay_order_id, razorpay_payment_id) FROM stdin;
4	9	2025-08-23 18:57:13.961535	1.00	Completed	sri@gmail.com	order_R8sn2pwhlyf26d	pay_R8snF3eP1pNFcA
5	14	2025-08-23 20:16:01.177902	1.00	Completed	srichityala501@gmail.com	order_R8u83hCdEGGxiW	pay_R8u8ThGoiLNCSQ
6	12	2025-08-27 15:53:56.139289	1.00	Completed	sri.chityala504@gmail.com	order_RAPnsahBFM5obN	pay_RAPo5nJs2jYAUa
7	12	2025-08-27 15:58:14.752533	1.00	Completed	sri.chityala504@gmail.com	order_RAPsPEz2y2RmSf	pay_RAPsfzu7rI5c0a
8	12	2025-08-27 16:03:32.792834	1.00	Completed	sri.chityala504@gmail.com	order_RAPy5aWg435Vip	pay_RAPyG6CrMeU92b
9	12	2025-08-27 16:09:56.675074	1.00	Completed	sri.chityala504@gmail.com	order_RAQ4nHTNhvkU6F	pay_RAQ50eT4ga4Lm2
10	12	2025-08-27 17:50:39.700312	1.00	Completed	sri.chityala504@gmail.com	order_RARmqXBIle0Oj2	pay_RARnNlvgPS8l3f
11	13	2025-09-13 17:58:17.805948	1.00	Completed	sri.chityala500@gmail.com	order_RHB0FCXTJuepdp	pay_RHB0WZgFEo6sMZ
12	13	2025-09-13 18:00:52.751262	1.00	Completed	sri.chityala500@gmail.com	order_RHB2z53jj7MkiT	pay_RHB3FOaGWvxrnU
13	13	2025-09-13 18:03:54.006192	1.00	Completed	sri.chityala500@gmail.com	order_RHB6A2oXHwXnad	pay_RHB6QwObtd7WSr
14	13	2025-09-13 18:14:37.920677	1.00	Completed	sri.chityala500@gmail.com	order_RHBHXQuhP4XZaW	pay_RHBHmKvEDNleVt
15	14	2025-09-13 18:54:27.450455	1.00	Completed	srichityala501@gmail.com	order_RHBxT8jCIONh3i	pay_RHBxr8U1eswvYR
16	14	2025-09-13 18:56:50.10443	1.00	Completed	srichityala501@gmail.com	order_RHC07bRbskaQvO	pay_RHC0L379i1eJYC
17	14	2025-09-13 19:06:05.344517	1.00	Completed	srichityala501@gmail.com	order_RHC9wHjoJJdjry	pay_RHCA8VUdLmO9V8
18	14	2025-09-13 19:10:26.598195	1.00	Completed	srichityala501@gmail.com	order_RHCEXCaX8m2b5c	pay_RHCEiLFv9apHeN
19	14	2025-09-13 19:17:17.245731	1.00	Completed	srichityala501@gmail.com	order_RHCLlQlFJetzwU	pay_RHCLy0dvBPuIKM
20	14	2025-09-13 19:26:10.335474	1.00	Completed	srichityala501@gmail.com	order_RHCV3q1MNxZRKZ	pay_RHCVLU241SrqF3
21	14	2025-09-13 19:27:31.1998	1.00	Completed	srichityala501@gmail.com	order_RHCWZ3pwAZWVIE	pay_RHCWlcr2EKARql
22	14	2025-09-13 20:00:38.429989	1.00	Completed	srichityala501@gmail.com	order_RHD5UsyjWm30JS	pay_RHD5kmmFMczGqr
23	14	2025-09-13 20:02:18.112725	1.00	Completed	srichityala501@gmail.com	order_RHD7K9BmbuO9cP	pay_RHD7USgozHDpT6
24	14	2025-09-13 20:09:01.077548	1.00	Completed	srichityala501@gmail.com	order_RHDESCQHUm7OZr	pay_RHDEcQVsb8jcgm
\.


--
-- Data for Name: product_sub_images; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.product_sub_images (id, product_id, image_url, description, created_at) FROM stdin;
3	7	img/Products/Screenshot_2025-09-07_at_7.42.48_PM.png	Brand & Model: Vergo Transform Prime\r\n\r\nColor: White Grey\r\n\r\nMaterial: Premium breathable mesh seat; nylon frame\r\n\r\nDimensions: 50D x 50W x 119H cm\r\n\r\nWeight: 20 kg | Max Load: 120 kg\r\n\r\nBack Style: High back, S-shaped ergonomic mesh\r\n\r\nFeatures:\r\n\r\nAdjustable height, lumbar, headrest, and 2D armrests\r\n\r\n2:1 multi-lock synchro tilt (90°–135°)\r\n\r\n360° swivel with 60mm dual wheels\r\n\r\nHigh-density molded foam seat for thigh support\r\n\r\nStyle: Transform Prime\r\n\r\nCare: Wipe clean\r\n\r\nAssembly & Warranty: DIY (10–20 mins) | 3-year warranty\r\n\r\nExtras: Breathable mesh keeps you cool; ergonomic design improves posture and reduces back pain	2025-09-07 14:14:41.650622
4	7	img/Products/Screenshot_2025-09-08_at_12.07.38_AM.png	Framed Wall Posters/Paintings with Frame (11 x 14 inch, Multi) Set of 3 (Modern Wall Decor, 3)	2025-09-07 18:38:49.601879
5	7	img/Products/Screenshot_2025-09-08_at_12.07.19_AM.png	Cord Organizer (160mm*80mm, Silver)	2025-09-07 18:39:35.747058
6	7	img/Products/Screenshot_2025-09-08_at_12.07.13_AM.png	Artificial Wall Grass for Home Decoration | 50 x 50 CM | Grass Mat Panel for Vertical Garden	2025-09-07 18:40:06.893591
7	7	img/Products/Screenshot_2025-09-08_at_12.07.00_AM.png	Plastic Artificial Plants With Pot Leaves Hanging Ivy Garlands Plant Greenery Vine Creeper Home Decor Door Wall Balcony Decoration Party - 50 Cm (2 Pcs Money Plants)	2025-09-07 18:40:33.187298
8	7	img/Products/Screenshot_2025-09-08_at_12.06.48_AM.png	Paris World Famous Building Small Metal Eiffel Tower Antique Vintage Statue for Gifting, Wedding,Room,Office,Decorative Showpeice for Home Decor, Desk Decor, Table Stand (15 cm)	2025-09-07 18:41:01.171151
9	7	img/Products/Screenshot_2025-09-08_at_12.06.24_AM.png	Harry Potter 3pc Set with pet Action Figure Special Edition Action Figure for Car Dashboard, Decoration, Cake, Office Desk & Study Table (Pack of 3) (Height-8 cm)	2025-09-07 18:41:24.773594
10	7	img/Products/Screenshot_2025-09-08_at_12.06.13_AM.png	Astronaut Spaceman Statue Ornament Home Office Desktop Figurine Decors Set of 3 - Golden (Golden)	2025-09-07 18:42:01.644386
11	7	img/Products/Screenshot_2025-09-08_at_12.06.00_AM.png	Portronics Power Plate 6 with 4 USB Port + 5 Power Sockets Extension Board, 2500W Power Converter, Cord Length 3Mtr (Black)	2025-09-07 18:42:22.352762
12	7	img/Products/Screenshot_2025-09-08_at_12.05.52_AM.png	3 Magnetic Cable Organizer Clips - Desk Wire Management Clip with 3M Adhesive Foam - Cord Holder for Desktop USB Charging Cables, Office, Home (Black)	2025-09-07 18:42:48.06152
13	7	img/Products/Screenshot_2025-09-08_at_12.05.39_AM.png	Digital Alarm Clock Table Clock for Students, Home, Office, Bedside Smart Timepiece for Heavy Sleepers, Automatic Sensor,Time,Date &Temperature, Alarm Clock for Bedroom 5 (MIROR Clock)	2025-09-07 18:43:11.505191
14	7	img/Products/Screenshot_2025-09-08_at_12.05.25_AM.png	Desk Lamp Black\r\nModern Minimalist Adjustable Reading Lamp Nordic Style Solid Natural Wood Metal	2025-09-07 18:43:36.134141
15	7	img/Products/Screenshot_2025-09-08_at_12.05.17_AM.png	Laptop Stand, Height-Adjustable, Foldable, Portable, Ventilated, Fits Up to 15.6-Inch Laptops (Aluminium Alloy, Silver) Tabletop	2025-09-07 18:43:53.697108
16	7	img/Products/Screenshot_2025-09-08_at_12.03.49_AM.png	Vanilla Reed Diffuser Set 50ml Smoke Less Room Freshener for Home Bedroom Living Room Office\r\nVanilla & Musk Blend of Toasted Coconut 5 Rattan Reed Sticks	2025-09-07 18:44:21.410627
17	7	img/Products/Screenshot_2025-09-10_at_1.29.49_AM.png	eather Dual Color Desk Mat 75X40cm 1.8mm Thick| Laptop Mat/Extended Large Mouse Pad, Reversible Deskspread	2025-09-09 20:00:34.508496
18	10	img/Products/ChatGPT_Image_Sep_10_2025_01_36_05_AM.png	table	2025-09-09 20:16:50.632696
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.products (id, name, description, category, price, rating, image_url, created_by, detailed_description) FROM stdin;
9	Scandi Minimal	Balanced simplicity with warm wood, neutral tones, and clutter-free design for a calming work vibe.	minimalist	1	5.0	img/Products/f996ebea3a130d8dd1bb5b2f1f938455.jpg	sri@gmail.com	\N
7	Green Wall Desk 	This desk provides the perfect balance of style and functionality.	ergonomic	65000	5.0	img/Products/1000397805.jpg	sri@gmail.com	Nature
11	Dual Harmony	A stylish side-by-side desk setup designed for couples who work, create, or study together. This shared workspace balances productivity with harmony.	couple	99000.0	5.0	img/Products/dualdesks_1.jpg	sri@gmail.com	\N
10	Neo Ergonomic Desk	Clean, modern workspace with an ergonomic chair, sleek desk, and fresh greenery for comfort and focus.	executive	58000.0	5.0	img/Products/grey_magic.JPG	sri@gmail.com	\N
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.reviews (id, product_id, user_id, username, rating, comment, created_at) FROM stdin;
1	7	\N	sri@gmail.com	5	Very comfortable 	2025-08-16 17:41:13.894303
2	7	14	chityala srikanth	4	good	2025-08-24 09:42:23.63162
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.users (id, name, email, password, address, phone) FROM stdin;
9	sri	sri@gmail.com	sri	\N	\N
10	Syed Ahmed	syed.ahmed8801302@gmail.com	aTNkZUoq	\N	\N
11	syed	syed@gmail.com	syed	\N	\N
12	Home	sri.chityala504@gmail.com		\N	\N
13	Sri ch	sri.chityala500@gmail.com	hello	\N	\N
15	Sreekanth Devops	sreekanththetechie@gmail.com	oauth_user_no_password_6lUorcIT7qfGlC3V	\N	\N
16	yamini chityala	chityalayamini@gmail.com	oauth_user_no_password_d69XXaVVlKg5aIG2	\N	\N
14	chityala srikanth	srichityala501@gmail.com			7075077384
\.


--
-- Name: cart_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.cart_id_seq', 28, true);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.order_items_id_seq', 21, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.orders_id_seq', 24, true);


--
-- Name: product_sub_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.product_sub_images_id_seq', 18, true);


--
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.products_id_seq', 14, true);


--
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.reviews_id_seq', 2, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.users_id_seq', 16, true);


--
-- Name: cart cart_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.cart
    ADD CONSTRAINT cart_pkey PRIMARY KEY (id);


--
-- Name: cart cart_user_product_unique; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.cart
    ADD CONSTRAINT cart_user_product_unique UNIQUE (user_id, product_id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: orders orders_razorpay_order_id_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_razorpay_order_id_key UNIQUE (razorpay_order_id);


--
-- Name: orders orders_razorpay_payment_id_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_razorpay_payment_id_key UNIQUE (razorpay_payment_id);


--
-- Name: product_sub_images product_sub_images_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_sub_images
    ADD CONSTRAINT product_sub_images_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: cart cart_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.cart
    ADD CONSTRAINT cart_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: cart cart_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.cart
    ADD CONSTRAINT cart_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE RESTRICT;


--
-- Name: orders orders_user_email_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_email_fkey FOREIGN KEY (user_email) REFERENCES public.users(email);


--
-- Name: orders orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: product_sub_images product_sub_images_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_sub_images
    ADD CONSTRAINT product_sub_images_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

