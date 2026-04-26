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

--
-- Name: auto_generate_referral_code(); Type: FUNCTION; Schema: public; Owner: sri
--

CREATE FUNCTION public.auto_generate_referral_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.referral_code IS NULL THEN
        NEW.referral_code := generate_referral_code(NEW.name, NEW.id);
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.auto_generate_referral_code() OWNER TO sri;

--
-- Name: generate_referral_code(text, integer); Type: FUNCTION; Schema: public; Owner: sri
--

CREATE FUNCTION public.generate_referral_code(user_name text, user_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    base_code VARCHAR(20);
    final_code VARCHAR(20);
    counter INTEGER := 0;
BEGIN
    -- Create base code from username (first 6 chars uppercase + user_id)
    base_code := UPPER(SUBSTRING(REGEXP_REPLACE(user_name, '[^a-zA-Z0-9]', '', 'g'), 1, 6)) || user_id;
    final_code := base_code;
    
    -- Check if code exists and add counter if needed
    WHILE EXISTS (SELECT 1 FROM users WHERE referral_code = final_code) LOOP
        counter := counter + 1;
        final_code := base_code || counter;
    END LOOP;
    
    RETURN final_code;
END;
$$;


ALTER FUNCTION public.generate_referral_code(user_name text, user_id integer) OWNER TO sri;

--
-- Name: update_blog_timestamp(); Type: FUNCTION; Schema: public; Owner: sri
--

CREATE FUNCTION public.update_blog_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_blog_timestamp() OWNER TO sri;

--
-- Name: update_product_rating(); Type: FUNCTION; Schema: public; Owner: sri
--

CREATE FUNCTION public.update_product_rating() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE products
    SET rating = (
        SELECT COALESCE(ROUND(AVG(rating)::numeric, 1), 0)
        FROM product_reviews
        WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)
        AND is_approved = TRUE
    )
    WHERE id = COALESCE(NEW.product_id, OLD.product_id);
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.update_product_rating() OWNER TO sri;

--
-- Name: update_review_count(); Type: FUNCTION; Schema: public; Owner: sri
--

CREATE FUNCTION public.update_review_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE products
    SET review_count = (
        SELECT COUNT(*)
        FROM product_reviews
        WHERE product_id = COALESCE(NEW.product_id, OLD.product_id)
        AND is_approved = TRUE
    )
    WHERE id = COALESCE(NEW.product_id, OLD.product_id);
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.update_review_count() OWNER TO sri;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_activity_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_activity_log (
    id integer NOT NULL,
    admin_user_id integer,
    action character varying(100) NOT NULL,
    target_type character varying(50),
    target_id integer,
    details text,
    ip_address character varying(45),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.admin_activity_log OWNER TO postgres;

--
-- Name: TABLE admin_activity_log; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.admin_activity_log IS 'Logs all admin actions for audit trail';


--
-- Name: admin_activity_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_activity_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_activity_log_id_seq OWNER TO postgres;

--
-- Name: admin_activity_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_activity_log_id_seq OWNED BY public.admin_activity_log.id;


--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_users (
    id integer NOT NULL,
    user_id integer,
    email character varying(255) NOT NULL,
    role character varying(20) NOT NULL,
    granted_by integer,
    granted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_access timestamp without time zone,
    is_active boolean DEFAULT true,
    notes text,
    CONSTRAINT admin_users_role_check CHECK (((role)::text = ANY ((ARRAY['read'::character varying, 'write'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.admin_users OWNER TO postgres;

--
-- Name: TABLE admin_users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.admin_users IS 'Stores admin users with role-based access control';


--
-- Name: COLUMN admin_users.role; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.admin_users.role IS 'Access level: read (view only), write (view + edit, no delete), admin (full access)';


--
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_users_id_seq OWNER TO postgres;

--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;


--
-- Name: blog_comments; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.blog_comments (
    id integer NOT NULL,
    blog_id integer NOT NULL,
    user_id integer NOT NULL,
    comment text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.blog_comments OWNER TO sri;

--
-- Name: blog_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.blog_comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.blog_comments_id_seq OWNER TO sri;

--
-- Name: blog_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.blog_comments_id_seq OWNED BY public.blog_comments.id;


--
-- Name: blog_media; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.blog_media (
    id integer NOT NULL,
    blog_id integer NOT NULL,
    media_type character varying(10) NOT NULL,
    media_url character varying(500) NOT NULL,
    media_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT blog_media_media_type_check CHECK (((media_type)::text = ANY ((ARRAY['image'::character varying, 'video'::character varying])::text[])))
);


ALTER TABLE public.blog_media OWNER TO sri;

--
-- Name: blog_media_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.blog_media_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.blog_media_id_seq OWNER TO sri;

--
-- Name: blog_media_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.blog_media_id_seq OWNED BY public.blog_media.id;


--
-- Name: blog_reactions; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.blog_reactions (
    id integer NOT NULL,
    blog_id integer NOT NULL,
    user_id integer,
    session_id character varying(255),
    reaction_type character varying(20) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT blog_reactions_check CHECK (((user_id IS NOT NULL) OR (session_id IS NOT NULL))),
    CONSTRAINT blog_reactions_reaction_type_check CHECK (((reaction_type)::text = ANY ((ARRAY['love'::character varying, 'fire'::character varying, 'happy'::character varying, 'wow'::character varying, 'clap'::character varying, 'heart'::character varying])::text[])))
);


ALTER TABLE public.blog_reactions OWNER TO sri;

--
-- Name: blog_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.blog_reactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.blog_reactions_id_seq OWNER TO sri;

--
-- Name: blog_reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.blog_reactions_id_seq OWNED BY public.blog_reactions.id;


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
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(100) NOT NULL,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: TABLE categories; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.categories IS 'Dynamic product categories managed by admin';


--
-- Name: COLUMN categories.display_order; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.categories.display_order IS 'Order in which categories appear in navigation (lower = first)';


--
-- Name: COLUMN categories.is_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.categories.is_active IS 'Whether category is visible to users';


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_id_seq OWNER TO postgres;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: coupon_usage; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.coupon_usage (
    id integer NOT NULL,
    coupon_id integer NOT NULL,
    user_id integer NOT NULL,
    order_id integer,
    discount_applied numeric(10,2) NOT NULL,
    used_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    discount_amount numeric(10,2) DEFAULT 0.00,
    referrer_bonus_amount numeric(10,2) DEFAULT 0.00,
    coupon_code character varying(50)
);


ALTER TABLE public.coupon_usage OWNER TO sri;

--
-- Name: TABLE coupon_usage; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.coupon_usage IS 'Tracks coupon usage to prevent duplicate usage by same user';


--
-- Name: coupon_usage_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.coupon_usage_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.coupon_usage_id_seq OWNER TO sri;

--
-- Name: coupon_usage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.coupon_usage_id_seq OWNED BY public.coupon_usage.id;


--
-- Name: coupons; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.coupons (
    id integer NOT NULL,
    code character varying(50) NOT NULL,
    discount_type character varying(20) NOT NULL,
    discount_value numeric(10,2) NOT NULL,
    description text,
    min_order_amount numeric(10,2) DEFAULT 0,
    max_discount_amount numeric(10,2),
    is_active boolean DEFAULT true,
    usage_limit integer,
    times_used integer DEFAULT 0,
    valid_from timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    valid_until timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by character varying(255),
    user_id integer,
    is_personal boolean DEFAULT false,
    CONSTRAINT coupons_discount_type_check CHECK (((discount_type)::text = ANY ((ARRAY['percentage'::character varying, 'fixed'::character varying])::text[])))
);


ALTER TABLE public.coupons OWNER TO sri;

--
-- Name: COLUMN coupons.user_id; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.coupons.user_id IS 'If NULL, coupon is public. If set, coupon is personal and only that user can use it.';


--
-- Name: COLUMN coupons.is_personal; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.coupons.is_personal IS 'TRUE if coupon is personal (user-specific), FALSE if public (everyone can use)';


--
-- Name: coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.coupons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.coupons_id_seq OWNER TO sri;

--
-- Name: coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.coupons_id_seq OWNED BY public.coupons.id;


--
-- Name: customer_blogs; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.customer_blogs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    title character varying(255) NOT NULL,
    content text NOT NULL,
    views integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    product_id integer
);


ALTER TABLE public.customer_blogs OWNER TO sri;

--
-- Name: customer_blogs_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.customer_blogs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customer_blogs_id_seq OWNER TO sri;

--
-- Name: customer_blogs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.customer_blogs_id_seq OWNED BY public.customer_blogs.id;


--
-- Name: discount; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.discount (
    id integer NOT NULL,
    discount_percent numeric(5,2) NOT NULL
);


ALTER TABLE public.discount OWNER TO sri;

--
-- Name: discount_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.discount_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.discount_id_seq OWNER TO sri;

--
-- Name: discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.discount_id_seq OWNED BY public.discount.id;


--
-- Name: gst_settings; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.gst_settings (
    id integer NOT NULL,
    gst_enabled boolean DEFAULT true,
    gst_rate numeric(5,4) DEFAULT 0.18,
    gst_number character varying(20) DEFAULT '36AORPG7724G1ZN'::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_by character varying(255),
    razorpay_key_gst character varying(100),
    razorpay_secret_gst character varying(100),
    razorpay_key_no_gst character varying(100),
    razorpay_secret_no_gst character varying(100)
);


ALTER TABLE public.gst_settings OWNER TO sri;

--
-- Name: gst_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.gst_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gst_settings_id_seq OWNER TO sri;

--
-- Name: gst_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.gst_settings_id_seq OWNED BY public.gst_settings.id;


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
    image_url character varying(255),
    deal_discount numeric DEFAULT 0,
    coupon_discount numeric DEFAULT 0,
    product_link character varying(500)
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
    razorpay_payment_id character varying(255) NOT NULL,
    coupon_code character varying(50),
    discount_amount numeric(10,2) DEFAULT 0,
    deal_discount numeric DEFAULT 0,
    coupon_discount numeric DEFAULT 0,
    status_code character varying(50),
    status_updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    shipping_name character varying(255),
    shipping_phone character varying(50),
    shipping_address_line_1 character varying(255),
    shipping_address_line_2 character varying(255),
    shipping_city character varying(120),
    shipping_state character varying(120),
    shipping_pincode character varying(20),
    shipping_country character varying(120),
    delivery_instructions text,
    company_name character varying(255),
    gstin character varying(30),
    wallet_amount_used numeric(10,2) DEFAULT 0.00,
    final_paid_amount numeric(10,2),
    cashback_earned numeric(10,2) DEFAULT 0.00,
    cashback_credited boolean DEFAULT false
);


ALTER TABLE public.orders OWNER TO sri;

--
-- Name: COLUMN orders.wallet_amount_used; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.orders.wallet_amount_used IS 'Amount paid from wallet for this order';


--
-- Name: COLUMN orders.cashback_earned; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.orders.cashback_earned IS 'Cashback earned on first order (5% of order value)';


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
-- Name: otp_verifications; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.otp_verifications (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    otp_code character varying(6) NOT NULL,
    name character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    attempts integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone NOT NULL,
    verified boolean DEFAULT false
);


ALTER TABLE public.otp_verifications OWNER TO sri;

--
-- Name: otp_verifications_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.otp_verifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.otp_verifications_id_seq OWNER TO sri;

--
-- Name: otp_verifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.otp_verifications_id_seq OWNED BY public.otp_verifications.id;


--
-- Name: product_reviews; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.product_reviews (
    id integer NOT NULL,
    product_id integer NOT NULL,
    user_id integer NOT NULL,
    order_id integer,
    rating integer NOT NULL,
    review_title character varying(200),
    review_text text,
    is_verified_purchase boolean DEFAULT false,
    is_approved boolean DEFAULT true,
    helpful_count integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT product_reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.product_reviews OWNER TO sri;

--
-- Name: TABLE product_reviews; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.product_reviews IS 'Stores customer reviews and ratings for products';


--
-- Name: product_reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.product_reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_reviews_id_seq OWNER TO sri;

--
-- Name: product_reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.product_reviews_id_seq OWNED BY public.product_reviews.id;


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
    detailed_description text,
    deal_percent numeric DEFAULT 0,
    review_count integer DEFAULT 0,
    category_id integer
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
-- Name: referral_coupons; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.referral_coupons (
    id integer NOT NULL,
    user_id integer NOT NULL,
    coupon_code character varying(20) NOT NULL,
    discount_percentage numeric(5,2) DEFAULT 5.00,
    referral_bonus_percentage numeric(5,2) DEFAULT 5.00,
    times_used integer DEFAULT 0,
    total_referral_earnings numeric(10,2) DEFAULT 0.00,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone,
    discount_type character varying(20) DEFAULT 'percentage'::character varying,
    discount_amount numeric(10,2) DEFAULT 0.00,
    referrer_bonus_type character varying(20) DEFAULT 'percentage'::character varying,
    referrer_bonus_amount numeric(10,2) DEFAULT 0.00,
    min_order_amount numeric(10,2) DEFAULT 0.00,
    max_discount_amount numeric(10,2),
    first_order_only boolean DEFAULT false,
    usage_limit integer,
    per_user_limit integer DEFAULT 1,
    description text
);


ALTER TABLE public.referral_coupons OWNER TO sri;

--
-- Name: TABLE referral_coupons; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.referral_coupons IS 'User-specific referral codes with 1-month expiry';


--
-- Name: referral_coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.referral_coupons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.referral_coupons_id_seq OWNER TO sri;

--
-- Name: referral_coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.referral_coupons_id_seq OWNED BY public.referral_coupons.id;


--
-- Name: review_helpful_votes; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.review_helpful_votes (
    id integer NOT NULL,
    review_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.review_helpful_votes OWNER TO sri;

--
-- Name: TABLE review_helpful_votes; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.review_helpful_votes IS 'Tracks which users found reviews helpful';


--
-- Name: review_helpful_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.review_helpful_votes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.review_helpful_votes_id_seq OWNER TO sri;

--
-- Name: review_helpful_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.review_helpful_votes_id_seq OWNED BY public.review_helpful_votes.id;


--
-- Name: review_media; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.review_media (
    id integer NOT NULL,
    review_id integer NOT NULL,
    media_url character varying(500) NOT NULL,
    media_type character varying(20) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT review_media_media_type_check CHECK (((media_type)::text = ANY ((ARRAY['image'::character varying, 'video'::character varying])::text[])))
);


ALTER TABLE public.review_media OWNER TO postgres;

--
-- Name: TABLE review_media; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.review_media IS 'Stores images and videos uploaded with product reviews';


--
-- Name: COLUMN review_media.media_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.review_media.media_url IS 'Relative URL path to the media file';


--
-- Name: COLUMN review_media.media_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.review_media.media_type IS 'Type of media: image or video';


--
-- Name: review_media_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.review_media_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.review_media_id_seq OWNER TO postgres;

--
-- Name: review_media_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.review_media_id_seq OWNED BY public.review_media.id;


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
    phone character varying(20),
    profile_photo character varying(255),
    address_line_2 character varying(255),
    city character varying(120),
    state character varying(120),
    pincode character varying(20),
    country character varying(120),
    landmark character varying(255),
    alternate_phone character varying(50),
    company_name character varying(255),
    gstin character varying(30),
    wallet_balance numeric(10,2) DEFAULT 0.00,
    wallet_bonus_limit numeric(10,2) DEFAULT 10000.00,
    referral_code character varying(20),
    referred_by_user_id integer,
    signup_bonus_credited boolean DEFAULT false,
    first_order_completed boolean DEFAULT false
);


ALTER TABLE public.users OWNER TO sri;

--
-- Name: COLUMN users.wallet_balance; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.users.wallet_balance IS 'Current wallet balance available for use';


--
-- Name: COLUMN users.wallet_bonus_limit; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.users.wallet_bonus_limit IS 'Maximum bonus amount that can be used per order (default 10000)';


--
-- Name: COLUMN users.referral_code; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.users.referral_code IS 'Unique referral code for each user';


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
-- Name: wallet_transactions; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.wallet_transactions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    transaction_type character varying(50) NOT NULL,
    amount numeric(10,2) NOT NULL,
    balance_after numeric(10,2) NOT NULL,
    description text,
    reference_type character varying(50),
    reference_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    metadata jsonb
);


ALTER TABLE public.wallet_transactions OWNER TO sri;

--
-- Name: TABLE wallet_transactions; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.wallet_transactions IS 'Tracks all wallet transactions including credits, debits, bonuses, and referrals';


--
-- Name: wallet_summary; Type: VIEW; Schema: public; Owner: sri
--

CREATE VIEW public.wallet_summary AS
 SELECT u.id AS user_id,
    u.name,
    u.email,
    u.wallet_balance,
    u.wallet_bonus_limit,
    u.referral_code,
    rc.times_used AS referral_uses,
    rc.total_referral_earnings,
    count(DISTINCT wt.id) AS total_transactions,
    COALESCE(sum(
        CASE
            WHEN ((wt.transaction_type)::text = 'credit'::text) THEN wt.amount
            ELSE (0)::numeric
        END), (0)::numeric) AS total_credits,
    COALESCE(sum(
        CASE
            WHEN ((wt.transaction_type)::text = 'debit'::text) THEN wt.amount
            ELSE (0)::numeric
        END), (0)::numeric) AS total_debits
   FROM ((public.users u
     LEFT JOIN public.referral_coupons rc ON ((u.id = rc.user_id)))
     LEFT JOIN public.wallet_transactions wt ON ((u.id = wt.user_id)))
  GROUP BY u.id, u.name, u.email, u.wallet_balance, u.wallet_bonus_limit, u.referral_code, rc.times_used, rc.total_referral_earnings;


ALTER VIEW public.wallet_summary OWNER TO sri;

--
-- Name: wallet_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.wallet_transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wallet_transactions_id_seq OWNER TO sri;

--
-- Name: wallet_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.wallet_transactions_id_seq OWNED BY public.wallet_transactions.id;


--
-- Name: wallets; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.wallets (
    id integer NOT NULL,
    user_id integer NOT NULL,
    balance numeric(10,2) DEFAULT 0.00 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT positive_balance CHECK ((balance >= (0)::numeric))
);


ALTER TABLE public.wallets OWNER TO sri;

--
-- Name: wallets_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.wallets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wallets_id_seq OWNER TO sri;

--
-- Name: wallets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.wallets_id_seq OWNED BY public.wallets.id;


--
-- Name: admin_activity_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_activity_log ALTER COLUMN id SET DEFAULT nextval('public.admin_activity_log_id_seq'::regclass);


--
-- Name: admin_users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users ALTER COLUMN id SET DEFAULT nextval('public.admin_users_id_seq'::regclass);


--
-- Name: blog_comments id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_comments ALTER COLUMN id SET DEFAULT nextval('public.blog_comments_id_seq'::regclass);


--
-- Name: blog_media id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_media ALTER COLUMN id SET DEFAULT nextval('public.blog_media_id_seq'::regclass);


--
-- Name: blog_reactions id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_reactions ALTER COLUMN id SET DEFAULT nextval('public.blog_reactions_id_seq'::regclass);


--
-- Name: cart id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.cart ALTER COLUMN id SET DEFAULT nextval('public.cart_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: coupon_usage id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage ALTER COLUMN id SET DEFAULT nextval('public.coupon_usage_id_seq'::regclass);


--
-- Name: coupons id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupons ALTER COLUMN id SET DEFAULT nextval('public.coupons_id_seq'::regclass);


--
-- Name: customer_blogs id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.customer_blogs ALTER COLUMN id SET DEFAULT nextval('public.customer_blogs_id_seq'::regclass);


--
-- Name: discount id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.discount ALTER COLUMN id SET DEFAULT nextval('public.discount_id_seq'::regclass);


--
-- Name: gst_settings id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.gst_settings ALTER COLUMN id SET DEFAULT nextval('public.gst_settings_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Name: otp_verifications id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.otp_verifications ALTER COLUMN id SET DEFAULT nextval('public.otp_verifications_id_seq'::regclass);


--
-- Name: product_reviews id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_reviews ALTER COLUMN id SET DEFAULT nextval('public.product_reviews_id_seq'::regclass);


--
-- Name: product_sub_images id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_sub_images ALTER COLUMN id SET DEFAULT nextval('public.product_sub_images_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: referral_coupons id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.referral_coupons ALTER COLUMN id SET DEFAULT nextval('public.referral_coupons_id_seq'::regclass);


--
-- Name: review_helpful_votes id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.review_helpful_votes ALTER COLUMN id SET DEFAULT nextval('public.review_helpful_votes_id_seq'::regclass);


--
-- Name: review_media id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.review_media ALTER COLUMN id SET DEFAULT nextval('public.review_media_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: wallet_transactions id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallet_transactions ALTER COLUMN id SET DEFAULT nextval('public.wallet_transactions_id_seq'::regclass);


--
-- Name: wallets id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallets ALTER COLUMN id SET DEFAULT nextval('public.wallets_id_seq'::regclass);


--
-- Data for Name: admin_activity_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_activity_log (id, admin_user_id, action, target_type, target_id, details, ip_address, created_at) FROM stdin;
1	4	add_admin_user	admin_user	\N	Added sri.chityala500@gmail.com with role admin	127.0.0.1	2026-04-19 15:32:41.54237
2	4	view_customers	customers	\N	Viewed customer list	127.0.0.1	2026-04-19 15:33:42.074777
\.


--
-- Data for Name: admin_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admin_users (id, user_id, email, role, granted_by, granted_at, last_access, is_active, notes) FROM stdin;
1	\N	admin@gspaces.com	admin	\N	2026-04-19 15:12:42.01859	\N	t	Super Admin - Full Access
3	\N	sri.chityala501@gmail.com	admin	\N	2026-04-19 15:31:47.078419	\N	t	Super Admin - Full Access
2	\N	sreekanth.chityala@gspaces.com	admin	\N	2026-04-19 15:12:48.237485	\N	t	Super Admin - Full Access
4	\N	srichityala501@gmail.com	admin	\N	2026-04-19 15:31:47.080163	2026-04-19 15:33:42.06296	t	Super Admin - Full Access
\.


--
-- Data for Name: blog_comments; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.blog_comments (id, blog_id, user_id, comment, created_at) FROM stdin;
\.


--
-- Data for Name: blog_media; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.blog_media (id, blog_id, media_type, media_url, media_order, created_at) FROM stdin;
28	20	image	img/blogs/blog_20_0_20260425100523_base-green.png	0	2026-04-25 10:05:23.543367
29	20	image	img/blogs/blog_20_1_20260425100523_Screenshot_2026-04-22_at_10.21.54_PM.png	1	2026-04-25 10:05:23.543367
30	20	video	img/blogs/blog_20_video_20260425100523_reel_01_2.mp4	2	2026-04-25 10:05:23.543367
\.


--
-- Data for Name: blog_reactions; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.blog_reactions (id, blog_id, user_id, session_id, reaction_type, created_at) FROM stdin;
8	20	14	\N	love	2026-04-26 07:00:48.015452
9	20	14	\N	fire	2026-04-26 07:00:48.905954
\.


--
-- Data for Name: cart; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.cart (id, user_id, product_id, quantity) FROM stdin;
97	32	30	1
98	14	31	1
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (id, name, slug, display_order, is_active, created_at, updated_at) FROM stdin;
1	Basic	basic	1	t	2026-04-23 15:29:08.789323	2026-04-23 15:29:08.789323
2	Storage	storage	2	t	2026-04-23 15:29:08.789323	2026-04-23 15:29:08.789323
3	Elegant	elegant	3	t	2026-04-23 15:29:08.789323	2026-04-23 15:29:08.789323
4	Greenery	greenery	4	t	2026-04-23 15:29:08.789323	2026-04-23 15:29:08.789323
5	Couple	couple	5	t	2026-04-23 15:29:08.789323	2026-04-23 15:29:08.789323
6	Luxury	luxury	6	t	2026-04-23 15:29:08.789323	2026-04-23 15:29:08.789323
7	Studio	studio	7	t	2026-04-23 15:29:08.789323	2026-04-23 15:29:08.789323
\.


--
-- Data for Name: coupon_usage; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.coupon_usage (id, coupon_id, user_id, order_id, discount_applied, used_at, discount_amount, referrer_bonus_amount, coupon_code) FROM stdin;
\.


--
-- Data for Name: coupons; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.coupons (id, code, discount_type, discount_value, description, min_order_amount, max_discount_amount, is_active, usage_limit, times_used, valid_from, valid_until, created_at, created_by, user_id, is_personal) FROM stdin;
2	DEEWALIFEST	percentage	2.00	2% Diwali festival discount	0.00	\N	f	\N	0	2026-04-11 05:45:10.405668	\N	2026-04-11 05:45:10.405668	sri.chityala501@gmail.com	\N	f
3	DASARAFEST	fixed	1000.00	₹1000 off on Dasara festival	0.00	\N	f	\N	0	2026-04-11 05:45:10.405668	\N	2026-04-11 05:45:10.405668	sri.chityala501@gmail.com	\N	f
1	NEWGSPACES	fixed	1000.00	1000 discount for new customers	0.00	\N	t	\N	0	2026-04-11 05:45:10.405668	\N	2026-04-11 05:45:10.405668	sri.chityala501@gmail.com	\N	f
4	SRI2026	fixed	5000.00		0.00	\N	f	\N	0	2026-04-15 08:14:34.387663	\N	2026-04-15 08:14:34.387663	srichityala501@gmail.com	\N	f
7	BONUS_GSPACES_FCC4	fixed	500.00	Personal coupon for gspaces	0.00	\N	t	\N	0	2026-04-18 14:52:25.891663	2026-07-17 14:52:25.893566	2026-04-18 14:52:25.891663	srichityala501@gmail.com	32	t
9	BONUS_GSPACES_MM8X	fixed	500.00	bonus	0.00	\N	t	\N	0	2026-04-18 15:21:16.973102	2026-07-17 15:21:17.853385	2026-04-18 15:21:16.973102	srichityala501@gmail.com	32	t
\.


--
-- Data for Name: customer_blogs; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.customer_blogs (id, user_id, title, content, views, created_at, updated_at, product_id) FROM stdin;
20	14	#basegreen Dream setup	<article style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">\n\n  <h2 style="color: #2c3e50;">A Clean &amp; Minimal Workspace with GSpaces</h2>\n\n  <p>\n    I wanted a workspace that feels clean, minimal, and distraction-free—and GSpaces delivered exactly that. \n    This setup is simple yet elegant, making it perfect for daily work and long productive hours.\n  </p>\n\n  <p>\n    The all-white desk gives a premium and modern look, while the ergonomic chair provides great comfort and support. \n    The soft lighting under the desk and behind adds a warm and relaxing vibe, especially during evening work sessions.\n  </p>\n\n  <p>\n    I really like the small details in this setup. The neatly placed shelf, tiny decor items, and plants add personality \n    without making the space feel crowded. Everything is well-organized, and the wide desk mat makes working more comfortable.\n  </p>\n\n  <p>\n    The plants on both sides bring a natural feel to the setup, making the environment fresh and lively. \n    It’s the kind of workspace where you can sit for hours without feeling stressed.\n  </p>\n\n  <p>\n    The experience with <strong>GSpaces</strong> was smooth from start to finish. They helped me choose the right design, \n    handled the setup professionally, and ensured everything was perfectly arranged.\n  </p>\n\n  <p>\n    If you prefer a neat and minimal workspace that still looks stylish, GSpaces is a great choice. \n    It’s not just about looks—it truly improves your focus and overall work experience.\n  </p>\n\n  <blockquote style="margin-top: 20px; padding: 10px 20px;">\n    “Minimal setup, maximum focus.”\n  </blockquote>\n\n</article>	13	2026-04-22 16:54:51.45978	2026-04-26 07:00:29.412853	7
\.


--
-- Data for Name: discount; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.discount (id, discount_percent) FROM stdin;
58	10.00
\.


--
-- Data for Name: gst_settings; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.gst_settings (id, gst_enabled, gst_rate, gst_number, updated_at, updated_by, razorpay_key_gst, razorpay_secret_gst, razorpay_key_no_gst, razorpay_secret_no_gst) FROM stdin;
1	f	0.1800	36AORPG7724G1ZN	2026-04-19 13:02:02.750161	srichityala501@gmail.com	rzp_live_R6wg6buSedSnTV	xeBC7q5tEirlDg4y4Tc3JEc3	rzp_live_R6wg6buSedSnTV	xeBC7q5tEirlDg4y4Tc3JEc3
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.order_items (id, order_id, product_id, quantity, price_at_purchase, product_name, image_url, deal_discount, coupon_discount, product_link) FROM stdin;
2	5	7	1	1.00	Green Wall Desk	img/Products/Screenshot_2025-08-16_at_10.48.06_PM.png	0	0	\N
43	52	30	1	1.00	Semi Wood (Get What You See)	img/Products/30/30.jpg	0	0	\N
45	54	30	1	1.00	Semi Wood (Get What You See)	img/Products/30/30.jpg	0	0	/product/30
46	55	30	1	1.00	Semi Wood (Get What You See)	img/Products/30/30.jpg	0	0	/product/30
47	56	30	1	1.00	Semi Wood (Get What You See)	img/Products/30/30.jpg	0	0	/product/30
48	57	30	1	0.90	Semi Wood (Get What You See)	img/Products/30/30.jpg	0	0	/product/30
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.orders (id, user_id, order_date, total_amount, status, user_email, razorpay_order_id, razorpay_payment_id, coupon_code, discount_amount, deal_discount, coupon_discount, status_code, status_updated_at, shipping_name, shipping_phone, shipping_address_line_1, shipping_address_line_2, shipping_city, shipping_state, shipping_pincode, shipping_country, delivery_instructions, company_name, gstin, wallet_amount_used, final_paid_amount, cashback_earned, cashback_credited) FROM stdin;
54	14	2026-04-11 04:21:05.979416	1.18	Confirmed	srichityala501@gmail.com	order_Sc3GDd4Ow8k9t1	pay_Sc3GWgrF73RTqh	\N	0.00	0	0	confirmed	2026-04-11 04:21:05.979413	chityala srikanth	7075077384	Hyderabad		Hyderabad	Telangana	500051	India				0.00	\N	0.00	f
5	14	2025-08-23 20:16:01.177902	1.00	Completed	srichityala501@gmail.com	order_R8u83hCdEGGxiW	pay_R8u8ThGoiLNCSQ	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
23	14	2025-09-13 20:02:18.112725	1.00	Completed	srichityala501@gmail.com	order_RHD7K9BmbuO9cP	pay_RHD7USgozHDpT6	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
24	14	2025-09-13 20:09:01.077548	1.00	Completed	srichityala501@gmail.com	order_RHDESCQHUm7OZr	pay_RHDEcQVsb8jcgm	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
32	14	2025-09-20 22:13:44.465179	1.18	Completed	srichityala501@gmail.com	order_RK163re8qx5JA7	pay_RK16BovwJLIOrW	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
33	14	2025-09-20 22:15:36.872055	1.18	Completed	srichityala501@gmail.com	order_RK17xDUYkH1IKq	pay_RK187buEqFtdUv	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
34	14	2025-09-20 22:18:00.334563	1.18	Completed	srichityala501@gmail.com	order_RK1AZ2a3G75qwz	pay_RK1AhFe1mMj2so	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
52	14	2026-04-10 06:52:46.51459	1.18	Completed	srichityala501@gmail.com	order_SbhIaGm9yqc70T	pay_SbhJa3WIAwl3dP	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
55	14	2026-04-11 04:24:39.717182	1.18	Confirmed	srichityala501@gmail.com	order_Sc3K3Lk5SMEQMI	pay_Sc3KJQUjr8I2D5	\N	0.00	0	0	confirmed	2026-04-11 04:24:39.717178	chityala srikanth	7075077384	Hyderabad		Hyderabad	Telangana	500051	India				0.00	\N	0.00	f
56	14	2026-04-11 04:29:53.848714	1.18	Delivered	srichityala501@gmail.com	order_Sc3PVrd41W2gY0	pay_Sc3PoFFe4a74U9	\N	0.00	0	0	delivered	2026-04-15 08:11:58.590029	chityala srikanth	7075077384	Hyderabad		Hyderabad	Telangana	500051	India				0.00	\N	0.00	f
21	14	2025-09-13 19:27:31.1998	1.00	Completed	srichityala501@gmail.com	order_RHCWZ3pwAZWVIE	pay_RHCWlcr2EKARql	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
22	14	2025-09-13 20:00:38.429989	1.00	Completed	srichityala501@gmail.com	order_RHD5UsyjWm30JS	pay_RHD5kmmFMczGqr	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
57	14	2026-04-11 06:58:12.742372	1.06	Delivered	srichityala501@gmail.com	order_Sc5w5pnDnWdwjm	pay_Sc5wSBlupwDrkf	\N	0.00	0	0	delivered	2026-04-11 07:14:07.886298	chityala srikanth	7075077384	Hyderabad		Hyderabad	Telangana	500051	India				0.00	\N	0.00	f
25	14	2025-09-20 15:49:29.600576	1.18	Completed	srichityala501@gmail.com	order_RJuY4dXif8w5I5	pay_RJuYJhkb54cnFo	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
26	14	2025-09-20 15:56:40.969307	1.18	Completed	srichityala501@gmail.com	order_RJufdLmlBvc3Ju	pay_RJufsy9MhV9v2Q	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
27	14	2025-09-20 21:44:30.015326	1.18	Completed	srichityala501@gmail.com	order_RK0b1S3qtTNas9	pay_RK0bII0mDzvvMc	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
28	14	2025-09-20 21:49:23.097919	1.18	Completed	srichityala501@gmail.com	order_RK0gCeIuR98nHr	pay_RK0gSR3gD5tqMx	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
29	14	2025-09-20 21:55:14.750662	1.18	Completed	srichityala501@gmail.com	order_RK0mT1oKWB8RLT	pay_RK0meyoBKGyLrW	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
30	14	2025-09-20 22:08:06.760943	1.00	Completed	srichityala501@gmail.com	order_RK0zz1uilbQHvj	pay_RK10GHnI7ZCyP7	\N	0.15	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
31	14	2025-09-20 22:10:36.104491	1.18	Completed	srichityala501@gmail.com	order_RK12hVyoQu8hSv	pay_RK12raFnZxKU84	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
15	14	2025-09-13 18:54:27.450455	1.00	Completed	srichityala501@gmail.com	order_RHBxT8jCIONh3i	pay_RHBxr8U1eswvYR	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
16	14	2025-09-13 18:56:50.10443	1.00	Completed	srichityala501@gmail.com	order_RHC07bRbskaQvO	pay_RHC0L379i1eJYC	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
17	14	2025-09-13 19:06:05.344517	1.00	Completed	srichityala501@gmail.com	order_RHC9wHjoJJdjry	pay_RHCA8VUdLmO9V8	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
18	14	2025-09-13 19:10:26.598195	1.00	Completed	srichityala501@gmail.com	order_RHCEXCaX8m2b5c	pay_RHCEiLFv9apHeN	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
19	14	2025-09-13 19:17:17.245731	1.00	Completed	srichityala501@gmail.com	order_RHCLlQlFJetzwU	pay_RHCLy0dvBPuIKM	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
20	14	2025-09-13 19:26:10.335474	1.00	Completed	srichityala501@gmail.com	order_RHCV3q1MNxZRKZ	pay_RHCVLU241SrqF3	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
41	14	2025-09-21 07:45:21.288893	1.18	Completed	srichityala501@gmail.com	order_RKApjUNjEhP6S0	pay_RKAq02mcEsKuti	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
43	14	2025-09-21 12:44:58.897377	1.18	Completed	srichityala501@gmail.com	order_RKFwEUlQ1yAlWi	pay_RKFwVFhPR6qVfN	\N	0.00	0.00	0.00	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
49	14	2025-10-12 18:19:06.555201	1.18	Completed	srichityala501@gmail.com	order_RSeqiQvsHN5uJd	pay_RSeqzdSQHqfJSX	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
50	14	2025-10-12 18:30:37.234285	1.18	Completed	srichityala501@gmail.com	order_RSf2rYm4k5RkKo	pay_RSf39bi7eJBSK2	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
51	14	2025-10-12 18:32:01.761722	1.42	Completed	srichityala501@gmail.com	order_RSf4QOuwurvfRF	pay_RSf4e10ZAg5EXr	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
\.


--
-- Data for Name: otp_verifications; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.otp_verifications (id, email, otp_code, name, password, attempts, created_at, expires_at, verified) FROM stdin;
4	srisaisagar789@gmail.com	332634	sai	998969	0	2026-04-18 15:26:37.320739	2026-04-18 15:31:37.320697	t
5	sri.chityala500@gmail.com	426424	sreekanth	998969	0	2026-04-23 14:09:04.493304	2026-04-23 14:14:04.493257	t
\.


--
-- Data for Name: product_reviews; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.product_reviews (id, product_id, user_id, order_id, rating, review_title, review_text, is_verified_purchase, is_approved, helpful_count, created_at, updated_at) FROM stdin;
1	10	14	\N	5	Very comfortable	Great ambience	f	t	0	2026-04-19 13:36:48.128185	2026-04-19 15:01:23.951479
\.


--
-- Data for Name: product_sub_images; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.product_sub_images (id, product_id, image_url, description, created_at) FROM stdin;
14	7	img/Products/Screenshot_2025-09-08_at_12.05.25_AM.png	Desk Lamp Black\r\nModern Minimalist Adjustable Reading Lamp Nordic Style Solid Natural Wood Metal	2025-09-07 18:43:36.134141
3	7	img/Products/Screenshot_2025-09-07_at_7.42.48_PM.png	Brand & Model: Vergo Transform Prime\r\n\r\nColor: White Grey\r\n\r\nMaterial: Premium breathable mesh seat; nylon frame\r\n\r\nDimensions: 50D x 50W x 119H cm\r\n\r\nWeight: 20 kg | Max Load: 120 kg\r\n\r\nBack Style: High back, S-shaped ergonomic mesh\r\n\r\nFeatures:\r\n\r\nAdjustable height, lumbar, headrest, and 2D armrests\r\n\r\n2:1 multi-lock synchro tilt (90°–135°)\r\n\r\n360° swivel with 60mm dual wheels\r\n\r\nHigh-density molded foam seat for thigh support\r\n\r\nStyle: Transform Prime\r\n\r\nCare: Wipe clean\r\n\r\nAssembly & Warranty: DIY (10–20 mins) | 3-year warranty\r\n\r\nExtras: Breathable mesh keeps you cool; ergonomic design improves posture and reduces back pain	2025-09-07 14:14:41.650622
4	7	img/Products/Screenshot_2025-09-08_at_12.07.38_AM.png	Framed Wall Posters/Paintings with Frame (11 x 14 inch, Multi) Set of 3 (Modern Wall Decor, 3)	2025-09-07 18:38:49.601879
17	7	img/Products/Screenshot_2025-09-14_at_12.09.11_PM.png	eather Dual Color Desk Mat 75X40cm 1.8mm Thick| Laptop Mat/Extended Large Mouse Pad, Reversible Deskspread	2025-09-09 20:00:34.508496
15	7	img/Products/Screenshot_2025-09-08_at_12.05.17_AM.png	Laptop Stand, Height-Adjustable, Foldable, Portable, Ventilated, Fits Up to 15.6-Inch Laptops (Aluminium Alloy, Silver) Tabletop	2025-09-07 18:43:53.697108
5	7	img/Products/Screenshot_2025-09-08_at_12.07.19_AM.png	Cord Organizer (160mm*80mm, Silver)	2025-09-07 18:39:35.747058
7	7	img/Products/Screenshot_2025-09-08_at_12.07.00_AM.png	Plastic Artificial Plants With Pot Leaves Hanging Ivy Garlands Plant Greenery Vine Creeper Home Decor Door Wall Balcony Decoration Party - 50 Cm (2 Pcs Money Plants)	2025-09-07 18:40:33.187298
6	7	img/Products/Screenshot_2025-09-08_at_12.07.13_AM.png	Artificial Wall Grass for Home Decoration | 50 x 50 CM | Grass Mat Panel for Vertical Garden(3 Pieces)	2025-09-07 18:40:06.893591
8	7	img/Products/Screenshot_2025-09-08_at_12.06.48_AM.png	Paris World Famous Building Small Metal Eiffel Tower Antique Vintage Statue for Gifting, Wedding,Room,Office,Decorative Showpeice for Home Decor, Desk Decor, Table Stand (15 cm)	2025-09-07 18:41:01.171151
9	7	img/Products/Screenshot_2025-09-08_at_12.06.24_AM.png	Harry Potter 3pc Set with pet Action Figure Special Edition Action Figure for Car Dashboard, Decoration, Cake, Office Desk & Study Table (Pack of 3) (Height-8 cm)	2025-09-07 18:41:24.773594
10	7	img/Products/Screenshot_2025-09-08_at_12.06.13_AM.png	Astronaut Spaceman Statue Ornament Home Office Desktop Figurine Decors Set of 3 - Golden (Golden)	2025-09-07 18:42:01.644386
16	7	img/Products/Screenshot_2025-09-08_at_12.03.49_AM.png	Vanilla Reed Diffuser Set 50ml Smoke Less Room Freshener for Home Bedroom Living Room Office\r\nVanilla & Musk Blend of Toasted Coconut 5 Rattan Reed Sticks	2025-09-07 18:44:21.410627
13	7	img/Products/Screenshot_2025-09-14_at_12.09.11_PM.png	Digital Alarm Clock Table Clock for Students, Home, Office, Bedside Smart Timepiece for Heavy Sleepers, Automatic Sensor,Time,Date &Temperature, Alarm Clock for Bedroom 5 (MIROR Clock)	2025-09-07 18:43:11.505191
11	7	img/Products/Screenshot_2025-09-14_at_12.19.35_PM.png	Portronics Power Plate 6 with 4 USB Port + 5 Power Sockets Extension Board, 2500W Power Converter, Cord Length 3Mtr (Black)	2025-09-07 18:42:22.352762
20	17	img/Products/Screenshot_2025-09-14_at_9.54.56_PM.png	<b>Fabric Study Arm Chair</b>\r\n<b>Highlights</b>\r\n<li>Adjustable Seat Height, Armrest, Wheels, Swivel\r\n<li>W x H: 75.6 cm x 98.5 cm (2 ft 5 in x 3 ft 2 in)\r\n<li>Frame Material: Plastic\r\n\r\n 	2025-09-14 16:31:05.026251
24	17	img/Products/Screenshot_2025-09-14_at_10.29.12_PM.png	<b>PVC Wooden Panel</b>\r\nSize: 1x9ft\r\n	2025-09-14 17:00:16.386098
27	17	img/Products/Screenshot_2025-09-15_at_12.28.06_AM.png	Leather Dual Color Desk Mat 60X35cm 1.8mm Thick	2025-09-14 18:58:41.900519
28	17	img/Products/Screenshot_2025-09-14_at_12.19.35_PM.png	Portronics Power Plate 7 with 6 USB Port + 8 Power Sockets Power Strip Extension Board with 2500W, 3Mtr Cord Length, 2.1A USB Output(Black), 250 Volts	2025-09-14 19:02:42.792785
29	17	img/Products/Screenshot_2025-09-15_at_12.34.51_AM.png	Aluminum Alloy Desk Grommet – Round Metal Cable Wire Hole Cover with Flip Dust-Proof Lid	2025-09-14 19:05:17.386867
41	10	img/Products/Screenshot_2025-09-14_at_12.08.40_PM.png	<b>Leather Dual Color Desk Mat 60X35cm 1.8mm Thick</b>	2025-09-14 20:42:13.380173
42	10	img/Products/Screenshot_2025-09-14_at_12.19.35_PM.png	<b>Portronics Power Plate 6 with 4 USB Port + 5 Power Sockets Extension Board, 2500W Power Converter, Cord Length 3Mtr (Black)	2025-09-14 20:45:21.217541
64	28	img/Products/Screenshot_2026-04-03_at_1.57.11_PM.png	Plant with 2ft height	2026-04-02 21:55:52.678026
22	17	img/Products/Office_Desk_Unit.png	<b>Wooden Study Table with 3 Layered Storage box</b>\r\n<li> <b>Material</b>: Plywood+ iron\r\n<li><b>Size</b>: 4x2ft\r\n\r\n	2025-09-14 16:54:42.45878
21	17	img/Products/White_Desk_Lamp.png	<b>White Desk Lamp</b>\r\n	2025-09-14 16:35:12.92153
25	17	img/Products/Illuminated_Shelves.png	Wooden rafter with Profile light\r\n<b>size</b>: 4x0.5ft(18mm)\r\n<b>count</b>: 3	2025-09-14 17:09:41.879254
26	17	img/Products/Screenshot_2025-09-15_at_12.26.03_AM.png	Natural plants with white pot\r\n<b>count: 4(Including Big Plant	2025-09-14 18:57:05.133432
43	10	img/Products/Screenshot_2025-09-15_at_2.16.13_AM.png	<b>EBCO Cable Organizer - ZINC(60MM)	2025-09-14 20:46:33.11741
44	10	img/Products/Screenshot_2025-09-15_at_2.16.46_AM.png	<b>Vanilla Reed Diffuser Set 50ml Smoke Less Room Freshener	2025-09-14 20:47:16.419606
46	10	img/Products/Screenshot_2025-09-15_at_2.18.10_AM.png	<b>Desk Lamp Black	2025-09-14 20:48:36.256188
47	10	img/Products/Screenshot_2025-09-15_at_2.19.05_AM.png	<b>Digital Alarm Clock Table Clock	2025-09-14 20:49:19.127837
48	10	img/Products/Screenshot_2025-09-15_at_2.19.35_AM.png	<b>Desk Organizer Desk Accessories Stand for Home/Office, White	2025-09-14 20:50:13.513154
49	10	img/Products/Screenshot_2025-09-15_at_2.20.25_AM.png	<b>Harry Potter 3pc Set with pet Action Figure Special Edition-Height-8 cm	2025-09-14 20:50:51.323341
50	10	img/Products/Screenshot_2025-09-15_at_2.12.31_AM.png	<b>Quotes Frames - Motivational Quotes Rectangular Wall Frames For Office - (14 X 11 Inches), Black	2025-09-14 20:52:00.763804
51	10	img/Products/Screenshot_2025-09-15_at_2.23.32_AM.png	<b>High Back Ergonomic Chair, 3D Armrest, Aluminum Base, Home, Study, Premium Mesh, Fabric Office Adjustable Arm Chair 	2025-09-14 20:54:20.750823
52	10	img/Products/Screenshot_2025-09-15_at_2.25.30_AM.png	<b> 4 Pcs Miniature Showpiece Set	2025-09-14 20:55:53.811052
53	10	img/Products/Screenshot_2025-09-15_at_2.25.58_AM.png	<b>Astronaut Spaceman Statue Ornament Home Office Desktop Figurine Decors Set of 3 - Golden	2025-09-14 20:56:24.221345
54	10	img/Products/Screenshot_2025-09-15_at_2.26.57_AM.png	<b>Palm Air Purifier Live Plant Natural Indoor and Outdoor Air Purifying Plant	2025-09-14 20:57:24.134627
91	25	img/Products/Wall_Mounted_Shelf_1.png	wall mounted box rack\r\nsize: 3x0.5ft and 8inch height	2026-04-03 07:45:56.075466
59	7	img/Products/ChatGPT_Image_Oct_17_2025_09_31_54_PM-Photoroom.png	Size: 5x2.25 ft 29inches height\r\n	2025-10-17 16:10:01.990393
60	28	img/Products/28/28_sub1.jpg	4x2 table size with white board and black legs	2026-04-02 21:55:52.678026
61	28	img/Products/28/28_sub2.jpg	Ergonomic chair with head rest \r\ncolour: Black	2026-04-02 21:55:52.678026
65	28	img/Products/28/28_sub6.jpg	Table plant	2026-04-02 21:55:52.678026
63	28	img/Products/28/28_sub4.jpg	12x15inches frame x2	2026-04-02 21:55:52.678026
66	29	img/Products/29/29_sub1.jpg	Table Size: 4x2ft 29'inches with white storage box	2026-04-02 22:05:22.996036
68	29	img/Products/29/29_sub3.jpg	Black Ergonomic Chair with Headrest\r\n	2026-04-02 22:05:22.996036
69	29	img/Products/29/29_sub4.jpg	Table Plants x4 units	2026-04-02 22:05:22.996036
71	29	img/Products/29/29_sub6.jpg	White Table lamp	2026-04-02 22:05:22.996036
62	28	img/Products/28/28_sub3.jpg	6x3inch black pen holder	2026-04-02 21:55:52.678026
72	22	img/Products/Modern_Desk_Unit.png	Wood Material: 701 grade Plywood\r\nsize: 5x2ft and 29' inch height\r\n4 Layered storage box	2026-04-03 06:51:59.878702
76	22	img/Products/Gray_Area_Rug.png	5x5 size fabric carpet	2026-04-03 06:57:10.738323
77	22	img/Products/Monochromatic_Landscape_Art.png	15x18 size frame	2026-04-03 06:57:39.202431
75	22	img/Products/Floating_Shelf_Display_1.png	White colour wooden rack	2026-04-03 06:56:04.33244
78	22	img/Products/Potted_Shelf_Plant.png	Mini plant with white pot	2026-04-03 07:06:01.080981
79	22	img/Products/Pen_Holder.png	6x3inches pen holder	2026-04-03 07:06:35.920774
81	24	img/Products/Dual_Black_Desk.png	Table: 8x2ft + 29' inch height \r\n3 layered storage\r\ncolour: black	2026-04-03 07:16:22.756417
92	25	img/Products/Large_Animal_Print.png	beige coloured frame\r\nsize: 15x18inches\r\nAdditional: mini frames\r\nunits: 3	2026-04-03 07:47:13.682368
93	25	img/Products/Golden_Metallic_Lamp.png	Gold coloured table lamp\r\nunit: 1	2026-04-03 07:48:32.285802
83	24	img/Products/Distressed_Gray_Rug.png	8x4ft carpet	2026-04-03 07:20:27.57703
82	24	img/Products/Desk_Mat_with_Peripherals_1.png	Deskmat\r\nunits: 2\r\nsize: 11x23inches\r\ncolour: cream	2026-04-03 07:18:22.038767
80	24	img/Products/Black_Desk_Lamp_1.png	gold coloured table lamp with warm light\r\nunits: 2	2026-04-03 07:14:53.980098
85	24	img/Products/Beige_Office_Chair.png	Roller soft chair\r\nunits: 2\r\ncolour: cream	2026-04-03 07:25:33.116993
86	24	img/Products/Empty_Floating_Shelves.png	wooden wall mounted racks\r\nunits: 4(2ft)\r\nhalf sized racks: 2(1ft)	2026-04-03 07:28:55.621355
87	24	img/Products/Assorted_Shelf_Plants.png	mini plants\r\nunits: 4	2026-04-03 07:29:38.84303
84	24	img/Products/Misty_Mountains_Art.png	12x24inches black bordered frame\r\nunit: 1\r\nAnd additional frame in multisize\r\nunits: 4	2026-04-03 07:21:27.062685
88	24	img/Products/Pen_Holder.png	pen holder\r\nsize: 6x3inch\r\nunits: 2	2026-04-03 07:34:16.876031
89	25	img/Products/Dual_Desk_Setup.png	Dual Table with storage\r\ntable size: 4x2ft 29' inch height\r\nstorage size: 1x1ft  29' inch height\r\ndraws: 4	2026-04-03 07:41:46.757228
90	25	img/Products/Ergonomic_Office_Chair.png	soft sitting ergonomic chair\r\nunits: 2	2026-04-03 07:42:30.211657
94	25	img/Products/Potted_Snake_Plant.png	table plant\r\nunits: 1\r\nAdditional: mini plants\r\nunits: 3	2026-04-03 07:49:17.778793
95	25	img/Products/Black_Mesh_Pen_Holder_1.png	pen holder:\r\nsize: 6x3inches\r\nunits: 2	2026-04-03 07:51:36.036375
96	23	img/Products/Ergonomic_Office_Chair.png	black seated ergonomic chair	2026-04-03 07:55:55.11201
97	23	img/Products/Natural_Wood_Desk.png	wooden table\r\nsize: 4x2ft 29'inch height	2026-04-03 07:56:31.835042
98	23	img/Products/Potted_Desk_Plants.png	plants\r\nunits: 3	2026-04-03 07:56:52.790266
99	23	img/Products/Large_Floor_Plants.png	plants dark brown colour\r\nunits: 2\r\nAdditional plants\r\nunits: 4	2026-04-03 07:57:19.336447
100	23	img/Products/Adjustable_Desk_Lamp.png	black table lamp	2026-04-03 07:58:00.943323
101	23	img/Products/Vertical_Garden_Wall.png	wall garden	2026-04-03 07:58:26.089716
102	26	img/Products/Executive_Desk.png	Wooden storage table\r\nsize: 5x2.25ft 29' inch height	2026-04-03 08:05:32.478653
103	26	img/Products/Illuminated_Shelf_and_Bookcase.png	Wall mounted storage with racks	2026-04-03 08:06:13.258115
104	26	img/Products/Left_Corner_Plant.png	Big corner plants\r\nunits: 2	2026-04-03 08:06:40.392859
105	26	img/Products/Office_Chairs.png	black comfortable premium chairs\r\nunits: 2	2026-04-03 08:07:36.301373
106	26	img/Products/Desk_Pen_Holder_Plant.png	mini plants\r\nunits: 4	2026-04-03 08:08:32.753992
107	26	img/Products/Spherical_Desk_Lamp.png	table rounded lamp\r\nunits: 2	2026-04-03 08:08:56.918399
108	26	img/Products/Area_Rug.png	floor carpet\r\nsize: 10x8ft	2026-04-03 08:09:47.833311
109	26	img/Products/Office_Wall_Surfaces.png	wall colour: dark grey	2026-04-03 08:13:15.933355
110	22	img/Products/22_1.jpg	soft blue wall paint	2026-04-03 08:20:03.232774
45	10	img/Products/mixboard-image.png	<b>Foldable & Portable Laptop Riser Stand Made with Aluminum Alloy	2025-09-14 20:47:56.927053
111	21	img/Products/Solid_Wood_Desk.png	4x2ft 29inch strong double wooden table\r\nMaterial: 701 grade plywood	2026-04-03 22:30:29.738916
112	21	img/Products/Ergonomic_Chair.png	ergonomic ash coloured chair with headrest	2026-04-03 22:30:58.622403
113	21	img/Products/Potted_Plant.png	table plant	2026-04-03 22:31:12.889922
114	21	img/Products/Utensil_Holder.png	pen holder	2026-04-03 22:31:23.460838
70	29	img/Products/Screenshot_2026-04-04_at_6.01.43_PM.png	Wall Wooden Rack with 3xframes	2026-04-02 22:05:22.996036
115	17	img/Products/Framed_Art_Group.png	Frames\r\nSizes\r\n1. 10x12\r\n2. 6x8	2026-04-04 12:54:53.028489
117	17	img/Products/Area_Rug.png	Ash coloured carpet\r\nsize: 4x4ft	2026-04-04 12:59:27.128046
118	30	img/Products/30/30_sub1.jpg	Table: semi wood with black iron legs\r\nsize: 4x2ft 29' inch height	2026-04-04 16:44:25.267882
119	30	img/Products/30/30_sub2.jpg	Ergonomic chair\r\ncolour: ash	2026-04-04 16:44:25.267882
120	30	img/Products/30/30_sub3.jpg	plant	2026-04-04 16:44:25.267882
121	30	img/Products/30/30_sub4.jpg	pen holder\r\nsize: 6x3inch's	2026-04-04 16:44:25.267882
123	22	img/Products/mixboard-image.png	Ergonomic Headrest Chair\r\ncolour: white with ash	2026-04-11 01:34:41.639868
124	22	img/Products/mixboard-image_1.png	Fragrance Diffuser 	2026-04-20 16:15:20.573326
125	22	img/Products/mixboard-image_2.png	Night Lamp	2026-04-20 16:18:17.381139
126	31	img/Products/31/31_sub1.jpg	Table size: 4x2 29inches height\r\ncolour: warm wood with black iron legs\r\n	2026-04-26 09:16:59.141034
127	31	img/Products/chair.png	Table with Headresr\r\ncolour: white ash \r\n	2026-04-26 09:18:13.856425
128	31	img/Products/lamp.png	Table lamp	2026-04-26 09:18:30.323454
129	31	img/Products/fragrancer.png	Fragrance to enhance productivity	2026-04-26 09:18:52.876221
130	31	img/Products/frames.png	Frames x 2\r\nsize: 12x15 inches	2026-04-26 09:19:22.092388
131	31	img/Products/gray_plant.png	plant	2026-04-26 09:19:40.80005
132	31	img/Products/mini-plants.png	mini plants x2	2026-04-26 09:19:51.62836
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.products (id, name, description, category, price, rating, image_url, created_by, detailed_description, deal_percent, review_count, category_id) FROM stdin;
10	Bright Space (Get What You See)	S-204	Storage	42000	5.0	img/Products/10/10.jpg	sri@gmail.com	Storage	0	1	\N
25	Individual Space (Get What You See)	C-402	Couple	60000.0	5.0	img/Products/C-402.png	srichityala501@gmail.com	\N	0	0	\N
24	Dual Minds (Get What You See)	C-401	Couple	68000.0	5.0	img/Products/C-401.png	srichityala501@gmail.com	\N	0	0	\N
7	Base Green (Get What You See)	S-201	Storage	48000	5.0	img/Products/7/7.jpg	sri@gmail.com	Nature	0	0	\N
17	Elegant Corner (Get What You See)	L-601	Elegant	60000.0	5.0	img/Products/17/17.jpg	srichityala501@gmail.com	\N	0	0	\N
23	Green Asset (Get What You See)	G-501	Greenery	60000.0	5.0	img/Products/23/23.jpg	srichityala501@gmail.com	\N	0	0	\N
31	Warm Wood	M-103	Basic	25000.0	5.0	img/Products/31/31.jpg	srichityala501@gmail.com	\N	0	0	\N
21	Magic Wood (Get What You See)	M-104	Basic	27000.0	4.0	img/Products/21/21.jpg	srichityala501@gmail.com	\N	0	0	\N
26	Dark Magic (Get What You See)	L-601	Luxury	90000.0	5.0	img/Products/26/26.jpg	srichityala501@gmail.com	\N	0	0	\N
29	Beige Minds (Get What You See)	S-206	Storage	38000.0	5.0	img/Products/29/29.jpg	srichityala501@gmail.com	\N	0	0	\N
27	Rafter Studio Setup (Get What You See)	S-701	Studio	150000.0	5.0	img/Products/27/27.jpg	srichityala501@gmail.com	\N	0	0	\N
30	Semi Wood (Get What You See)	M-101	Basic	20000	5.0	img/Products/30/30.jpg	srichityala501@gmail.com	\N	0	0	\N
22	Soft Sky (Get What You See)	E-303	Elegant	48000.0	5.0	img/Products/22/22.jpg	srichityala501@gmail.com	\N	0	0	\N
28	Scandi Minimal (Get What You See)	M-102	Basic	25000.0	5.0	img/Products/28/28.jpg	srichityala501@gmail.com	\N	0	0	\N
\.


--
-- Data for Name: referral_coupons; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.referral_coupons (id, user_id, coupon_code, discount_percentage, referral_bonus_percentage, times_used, total_referral_earnings, is_active, created_at, expires_at, discount_type, discount_amount, referrer_bonus_type, referrer_bonus_amount, min_order_amount, max_discount_amount, first_order_only, usage_limit, per_user_limit, description) FROM stdin;
68	34	SREEKA34	5.00	5.00	0	0.00	t	2026-04-23 14:09:30.695614	2027-04-23 14:09:30.695618	percentage	0.00	percentage	0.00	0.00	\N	f	\N	1	\N
4	15	SREEKA15	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
6	17	VIJAYK17	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
10	20	VIJAYK20	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
17	27	VISHNU27	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
18	14	CHITYA14	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 00:00:00	fixed	500.00	fixed	499.97	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
66	32	GSPACE32	10.00	10.00	0	0.00	f	2026-04-18 11:37:41.683389	2026-04-18 00:00:00	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
\.


--
-- Data for Name: review_helpful_votes; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.review_helpful_votes (id, review_id, user_id, created_at) FROM stdin;
\.


--
-- Data for Name: review_media; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.review_media (id, review_id, media_url, media_type, created_at) FROM stdin;
1	1	/static/img/reviews/review_14_10_1776610883_DSC06885-1280x720.jpg	image	2026-04-19 15:01:23.951479
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

COPY public.users (id, name, email, password, address, phone, profile_photo, address_line_2, city, state, pincode, country, landmark, alternate_phone, company_name, gstin, wallet_balance, wallet_bonus_limit, referral_code, referred_by_user_id, signup_bonus_credited, first_order_completed) FROM stdin;
15	Sreekanth Devops	sreekanththetechie@gmail.com	998969	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	SREEKA15	\N	t	f
34	sreekanth	sri.chityala500@gmail.com	998969	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	SREEKA34	\N	t	f
17	Vijay Kumar	sri.vijaychittiyala@gmail.com	D@rk#0rse	\N	7416542354	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	VIJAYK17	\N	t	f
20	vijay kumar chityala	sri.vijaychityala@gmail.com	oauth_user_no_password_P6gvG8zHXcjvzhuh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	VIJAYK20	\N	t	f
27	Vishnu Chityala	vishnurchityala@gmail.com	oauth_user_no_password_iaPILT6luNGdt4Ln	\N	9537234000	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	VISHNU27	\N	t	f
14	chityala srikanth	srichityala501@gmail.com		Hyderabad	7075077384	img/profiles/user_14_1775881216.png		Hyderabad	Telangana	500051	India					500.00	10000.00	CHITYA14	\N	t	f
32	gspaces	gspaces2025@gmail.com	oauth_user_no_password_KthRRpoNZQ62vltK	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	GSPACE32	\N	t	f
\.


--
-- Data for Name: wallet_transactions; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.wallet_transactions (id, user_id, transaction_type, amount, balance_after, description, reference_type, reference_id, created_at, metadata) FROM stdin;
4	15	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
6	17	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
10	20	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
17	27	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
18	14	bonus	500.00	500.00	Welcome bonus - Thank you for joining GSpaces!	signup	\N	2026-04-17 18:40:08.621001	\N
23	32	bonus	500.00	500.00	Welcome bonus for gspaces	signup	\N	2026-04-18 11:17:34.318248	{"bonus_type": "signup"}
28	32	admin_credit	100.00	600.00	Admin adjustment by srichityala501@gmail.com	\N	\N	2026-04-18 14:19:34.397815	\N
30	34	bonus	500.00	500.00	Welcome bonus for sreekanth	signup	\N	2026-04-23 14:09:30.691501	{"bonus_type": "signup"}
\.


--
-- Data for Name: wallets; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.wallets (id, user_id, balance, created_at, updated_at) FROM stdin;
24	32	600.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
4	15	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
6	17	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
10	20	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
17	27	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
18	14	500.00	2026-04-18 13:42:28.630256	2026-04-18 13:54:44.734584
\.


--
-- Name: admin_activity_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_activity_log_id_seq', 2, true);


--
-- Name: admin_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_users_id_seq', 6, true);


--
-- Name: blog_comments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.blog_comments_id_seq', 1, false);


--
-- Name: blog_media_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.blog_media_id_seq', 30, true);


--
-- Name: blog_reactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.blog_reactions_id_seq', 9, true);


--
-- Name: cart_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.cart_id_seq', 98, true);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_id_seq', 14, true);


--
-- Name: coupon_usage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.coupon_usage_id_seq', 1, false);


--
-- Name: coupons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.coupons_id_seq', 9, true);


--
-- Name: customer_blogs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.customer_blogs_id_seq', 20, true);


--
-- Name: discount_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.discount_id_seq', 58, true);


--
-- Name: gst_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.gst_settings_id_seq', 1, true);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.order_items_id_seq', 48, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.orders_id_seq', 57, true);


--
-- Name: otp_verifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.otp_verifications_id_seq', 5, true);


--
-- Name: product_reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.product_reviews_id_seq', 2, true);


--
-- Name: product_sub_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.product_sub_images_id_seq', 132, true);


--
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.products_id_seq', 31, true);


--
-- Name: referral_coupons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.referral_coupons_id_seq', 68, true);


--
-- Name: review_helpful_votes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.review_helpful_votes_id_seq', 1, false);


--
-- Name: review_media_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.review_media_id_seq', 1, true);


--
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.reviews_id_seq', 2, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.users_id_seq', 34, true);


--
-- Name: wallet_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.wallet_transactions_id_seq', 30, true);


--
-- Name: wallets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.wallets_id_seq', 28, true);


--
-- Name: admin_activity_log admin_activity_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_activity_log
    ADD CONSTRAINT admin_activity_log_pkey PRIMARY KEY (id);


--
-- Name: admin_users admin_users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_email_key UNIQUE (email);


--
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: blog_comments blog_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_comments
    ADD CONSTRAINT blog_comments_pkey PRIMARY KEY (id);


--
-- Name: blog_media blog_media_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_media
    ADD CONSTRAINT blog_media_pkey PRIMARY KEY (id);


--
-- Name: blog_reactions blog_reactions_blog_id_session_id_reaction_type_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_reactions
    ADD CONSTRAINT blog_reactions_blog_id_session_id_reaction_type_key UNIQUE (blog_id, session_id, reaction_type);


--
-- Name: blog_reactions blog_reactions_blog_id_user_id_reaction_type_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_reactions
    ADD CONSTRAINT blog_reactions_blog_id_user_id_reaction_type_key UNIQUE (blog_id, user_id, reaction_type);


--
-- Name: blog_reactions blog_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_reactions
    ADD CONSTRAINT blog_reactions_pkey PRIMARY KEY (id);


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
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: categories categories_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_slug_key UNIQUE (slug);


--
-- Name: coupon_usage coupon_usage_coupon_id_order_id_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_coupon_id_order_id_key UNIQUE (coupon_id, order_id);


--
-- Name: coupon_usage coupon_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_pkey PRIMARY KEY (id);


--
-- Name: coupons coupons_code_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_code_key UNIQUE (code);


--
-- Name: coupons coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);


--
-- Name: customer_blogs customer_blogs_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.customer_blogs
    ADD CONSTRAINT customer_blogs_pkey PRIMARY KEY (id);


--
-- Name: discount discount_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.discount
    ADD CONSTRAINT discount_pkey PRIMARY KEY (id);


--
-- Name: gst_settings gst_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.gst_settings
    ADD CONSTRAINT gst_settings_pkey PRIMARY KEY (id);


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
-- Name: otp_verifications otp_verifications_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.otp_verifications
    ADD CONSTRAINT otp_verifications_pkey PRIMARY KEY (id);


--
-- Name: product_reviews product_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_reviews
    ADD CONSTRAINT product_reviews_pkey PRIMARY KEY (id);


--
-- Name: product_reviews product_reviews_product_id_user_id_order_id_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_reviews
    ADD CONSTRAINT product_reviews_product_id_user_id_order_id_key UNIQUE (product_id, user_id, order_id);


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
-- Name: referral_coupons referral_coupons_coupon_code_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.referral_coupons
    ADD CONSTRAINT referral_coupons_coupon_code_key UNIQUE (coupon_code);


--
-- Name: referral_coupons referral_coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.referral_coupons
    ADD CONSTRAINT referral_coupons_pkey PRIMARY KEY (id);


--
-- Name: review_helpful_votes review_helpful_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.review_helpful_votes
    ADD CONSTRAINT review_helpful_votes_pkey PRIMARY KEY (id);


--
-- Name: review_helpful_votes review_helpful_votes_review_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.review_helpful_votes
    ADD CONSTRAINT review_helpful_votes_review_id_user_id_key UNIQUE (review_id, user_id);


--
-- Name: review_media review_media_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.review_media
    ADD CONSTRAINT review_media_pkey PRIMARY KEY (id);


--
-- Name: review_media review_media_review_id_media_url_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.review_media
    ADD CONSTRAINT review_media_review_id_media_url_key UNIQUE (review_id, media_url);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: referral_coupons unique_user_referral; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.referral_coupons
    ADD CONSTRAINT unique_user_referral UNIQUE (user_id);


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
-- Name: users users_referral_code_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_referral_code_key UNIQUE (referral_code);


--
-- Name: wallet_transactions wallet_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_pkey PRIMARY KEY (id);


--
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (id);


--
-- Name: wallets wallets_user_id_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_key UNIQUE (user_id);


--
-- Name: idx_admin_activity_log_admin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admin_activity_log_admin ON public.admin_activity_log USING btree (admin_user_id);


--
-- Name: idx_admin_activity_log_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admin_activity_log_created ON public.admin_activity_log USING btree (created_at DESC);


--
-- Name: idx_admin_users_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admin_users_active ON public.admin_users USING btree (is_active);


--
-- Name: idx_admin_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admin_users_email ON public.admin_users USING btree (email);


--
-- Name: idx_admin_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admin_users_role ON public.admin_users USING btree (role);


--
-- Name: idx_blog_comments_blog_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_blog_comments_blog_id ON public.blog_comments USING btree (blog_id);


--
-- Name: idx_blog_media_blog_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_blog_media_blog_id ON public.blog_media USING btree (blog_id);


--
-- Name: idx_blog_reactions_blog_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_blog_reactions_blog_id ON public.blog_reactions USING btree (blog_id);


--
-- Name: idx_blog_reactions_type; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_blog_reactions_type ON public.blog_reactions USING btree (reaction_type);


--
-- Name: idx_blogs_created_at; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_blogs_created_at ON public.customer_blogs USING btree (created_at DESC);


--
-- Name: idx_blogs_product_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_blogs_product_id ON public.customer_blogs USING btree (product_id);


--
-- Name: idx_blogs_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_blogs_user_id ON public.customer_blogs USING btree (user_id);


--
-- Name: idx_categories_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categories_active ON public.categories USING btree (is_active);


--
-- Name: idx_categories_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categories_order ON public.categories USING btree (display_order);


--
-- Name: idx_categories_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categories_slug ON public.categories USING btree (slug);


--
-- Name: idx_coupon_usage_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_coupon_usage_user_id ON public.coupon_usage USING btree (user_id);


--
-- Name: idx_coupons_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_coupons_user_id ON public.coupons USING btree (user_id);


--
-- Name: idx_otp_email; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_otp_email ON public.otp_verifications USING btree (email);


--
-- Name: idx_otp_expires; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_otp_expires ON public.otp_verifications USING btree (expires_at);


--
-- Name: idx_product_reviews_created_at; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_product_reviews_created_at ON public.product_reviews USING btree (created_at DESC);


--
-- Name: idx_product_reviews_product_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_product_reviews_product_id ON public.product_reviews USING btree (product_id);


--
-- Name: idx_product_reviews_rating; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_product_reviews_rating ON public.product_reviews USING btree (rating);


--
-- Name: idx_product_reviews_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_product_reviews_user_id ON public.product_reviews USING btree (user_id);


--
-- Name: idx_products_category_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_products_category_id ON public.products USING btree (category_id);


--
-- Name: idx_referral_coupons_active; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_referral_coupons_active ON public.referral_coupons USING btree (is_active);


--
-- Name: idx_referral_coupons_code; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_referral_coupons_code ON public.referral_coupons USING btree (coupon_code);


--
-- Name: idx_referral_coupons_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_referral_coupons_user_id ON public.referral_coupons USING btree (user_id);


--
-- Name: idx_review_helpful_votes_review_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_review_helpful_votes_review_id ON public.review_helpful_votes USING btree (review_id);


--
-- Name: idx_review_media_review_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_review_media_review_id ON public.review_media USING btree (review_id);


--
-- Name: idx_users_referral_code; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_users_referral_code ON public.users USING btree (referral_code);


--
-- Name: idx_wallet_transactions_created_at; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_wallet_transactions_created_at ON public.wallet_transactions USING btree (created_at DESC);


--
-- Name: idx_wallet_transactions_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_wallet_transactions_user_id ON public.wallet_transactions USING btree (user_id);


--
-- Name: idx_wallets_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_wallets_user_id ON public.wallets USING btree (user_id);


--
-- Name: users trigger_auto_referral_code; Type: TRIGGER; Schema: public; Owner: sri
--

CREATE TRIGGER trigger_auto_referral_code BEFORE INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.auto_generate_referral_code();


--
-- Name: product_reviews trigger_update_product_rating; Type: TRIGGER; Schema: public; Owner: sri
--

CREATE TRIGGER trigger_update_product_rating AFTER INSERT OR DELETE OR UPDATE ON public.product_reviews FOR EACH ROW EXECUTE FUNCTION public.update_product_rating();


--
-- Name: product_reviews trigger_update_review_count; Type: TRIGGER; Schema: public; Owner: sri
--

CREATE TRIGGER trigger_update_review_count AFTER INSERT OR DELETE OR UPDATE ON public.product_reviews FOR EACH ROW EXECUTE FUNCTION public.update_review_count();


--
-- Name: customer_blogs update_blog_timestamp; Type: TRIGGER; Schema: public; Owner: sri
--

CREATE TRIGGER update_blog_timestamp BEFORE UPDATE ON public.customer_blogs FOR EACH ROW EXECUTE FUNCTION public.update_blog_timestamp();


--
-- Name: admin_activity_log admin_activity_log_admin_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_activity_log
    ADD CONSTRAINT admin_activity_log_admin_user_id_fkey FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id) ON DELETE CASCADE;


--
-- Name: admin_users admin_users_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: admin_users admin_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: blog_comments blog_comments_blog_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_comments
    ADD CONSTRAINT blog_comments_blog_id_fkey FOREIGN KEY (blog_id) REFERENCES public.customer_blogs(id) ON DELETE CASCADE;


--
-- Name: blog_comments blog_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_comments
    ADD CONSTRAINT blog_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: blog_media blog_media_blog_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_media
    ADD CONSTRAINT blog_media_blog_id_fkey FOREIGN KEY (blog_id) REFERENCES public.customer_blogs(id) ON DELETE CASCADE;


--
-- Name: blog_reactions blog_reactions_blog_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_reactions
    ADD CONSTRAINT blog_reactions_blog_id_fkey FOREIGN KEY (blog_id) REFERENCES public.customer_blogs(id) ON DELETE CASCADE;


--
-- Name: blog_reactions blog_reactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.blog_reactions
    ADD CONSTRAINT blog_reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


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
-- Name: coupon_usage coupon_usage_coupon_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_coupon_id_fkey FOREIGN KEY (coupon_id) REFERENCES public.coupons(id) ON DELETE CASCADE;


--
-- Name: coupon_usage coupon_usage_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE SET NULL;


--
-- Name: coupon_usage coupon_usage_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: coupons coupons_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: customer_blogs customer_blogs_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.customer_blogs
    ADD CONSTRAINT customer_blogs_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: customer_blogs customer_blogs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.customer_blogs
    ADD CONSTRAINT customer_blogs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


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
-- Name: product_reviews product_reviews_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_reviews
    ADD CONSTRAINT product_reviews_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE SET NULL;


--
-- Name: product_reviews product_reviews_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_reviews
    ADD CONSTRAINT product_reviews_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_reviews product_reviews_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_reviews
    ADD CONSTRAINT product_reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: product_sub_images product_sub_images_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.product_sub_images
    ADD CONSTRAINT product_sub_images_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: products products_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: referral_coupons referral_coupons_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.referral_coupons
    ADD CONSTRAINT referral_coupons_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: review_helpful_votes review_helpful_votes_review_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.review_helpful_votes
    ADD CONSTRAINT review_helpful_votes_review_id_fkey FOREIGN KEY (review_id) REFERENCES public.product_reviews(id) ON DELETE CASCADE;


--
-- Name: review_helpful_votes review_helpful_votes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.review_helpful_votes
    ADD CONSTRAINT review_helpful_votes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: review_media review_media_review_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.review_media
    ADD CONSTRAINT review_media_review_id_fkey FOREIGN KEY (review_id) REFERENCES public.product_reviews(id) ON DELETE CASCADE;


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
-- Name: users users_referred_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_referred_by_user_id_fkey FOREIGN KEY (referred_by_user_id) REFERENCES public.users(id);


--
-- Name: wallet_transactions wallet_transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: wallets wallets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

