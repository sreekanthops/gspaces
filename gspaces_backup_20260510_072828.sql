--
-- PostgreSQL database dump
--

\restrict c15xOwbe00wNPZLPw7xv1Hd0zyrFELO4KlrBsWowUR97QH29zrgJwWvdpcsvLKq

-- Dumped from database version 15.16
-- Dumped by pg_dump version 15.16

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
-- Name: update_customer_inquiry_timestamp(); Type: FUNCTION; Schema: public; Owner: sri
--

CREATE FUNCTION public.update_customer_inquiry_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_customer_inquiry_timestamp() OWNER TO sri;

--
-- Name: update_default_items_timestamp(); Type: FUNCTION; Schema: public; Owner: sri
--

CREATE FUNCTION public.update_default_items_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_default_items_timestamp() OWNER TO sri;

--
-- Name: update_leads_timestamp(); Type: FUNCTION; Schema: public; Owner: sri
--

CREATE FUNCTION public.update_leads_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_leads_timestamp() OWNER TO sri;

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

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: category_discounts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.category_discounts (
    id integer NOT NULL,
    campaign_id integer,
    category_id integer,
    category_name character varying(255) NOT NULL,
    discount_percent numeric(5,2) DEFAULT 0.00 NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.category_discounts OWNER TO postgres;

--
-- Name: deal_campaigns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.deal_campaigns (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    is_active boolean DEFAULT false,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    countdown_duration integer DEFAULT 0,
    banner_text character varying(500) DEFAULT 'Limited Time Offer - Save Big Today!'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.deal_campaigns OWNER TO postgres;

--
-- Name: global_discount; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.global_discount (
    id integer NOT NULL,
    campaign_id integer,
    discount_percent numeric(5,2) DEFAULT 0.00 NOT NULL,
    is_active boolean DEFAULT false,
    priority integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.global_discount OWNER TO postgres;

--
-- Name: active_deals_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.active_deals_view AS
 SELECT dc.id AS campaign_id,
    dc.name AS campaign_name,
    dc.banner_text,
    dc.end_time,
    dc.countdown_duration,
    cd.category_id,
    cd.category_name,
    cd.discount_percent AS category_discount,
    gd.discount_percent AS global_discount,
    gd.priority AS global_priority,
        CASE
            WHEN ((gd.is_active = true) AND (gd.priority > 0)) THEN gd.discount_percent
            ELSE cd.discount_percent
        END AS effective_discount
   FROM ((public.deal_campaigns dc
     LEFT JOIN public.category_discounts cd ON (((dc.id = cd.campaign_id) AND (cd.is_active = true))))
     LEFT JOIN public.global_discount gd ON (((dc.id = gd.campaign_id) AND (gd.is_active = true))))
  WHERE ((dc.is_active = true) AND ((dc.end_time IS NULL) OR (dc.end_time > now())));


ALTER TABLE public.active_deals_view OWNER TO postgres;

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


ALTER TABLE public.admin_activity_log_id_seq OWNER TO postgres;

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
    CONSTRAINT admin_users_role_check CHECK (((role)::text = ANY (ARRAY[('read'::character varying)::text, ('write'::character varying)::text, ('admin'::character varying)::text])))
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


ALTER TABLE public.admin_users_id_seq OWNER TO postgres;

--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;


--
-- Name: animated_banner_settings; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.animated_banner_settings (
    id integer NOT NULL,
    is_enabled boolean DEFAULT true,
    scatter_duration integer DEFAULT 2000,
    scatter_easing character varying(50) DEFAULT 'ease-out'::character varying,
    allow_drag boolean DEFAULT true,
    snap_to_grid boolean DEFAULT false,
    grid_size integer DEFAULT 20,
    show_reset_button boolean DEFAULT true,
    background_color character varying(20) DEFAULT '#f8f9fa'::character varying,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.animated_banner_settings OWNER TO sri;

--
-- Name: TABLE animated_banner_settings; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.animated_banner_settings IS 'Configuration settings for animated banner behavior';


--
-- Name: animated_banner_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.animated_banner_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.animated_banner_settings_id_seq OWNER TO sri;

--
-- Name: animated_banner_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.animated_banner_settings_id_seq OWNED BY public.animated_banner_settings.id;


--
-- Name: animated_furniture_items; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.animated_furniture_items (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    image_path character varying(255) NOT NULL,
    category character varying(50) NOT NULL,
    width integer DEFAULT 100 NOT NULL,
    height integer DEFAULT 100 NOT NULL,
    initial_x numeric(5,2) DEFAULT 50.0,
    initial_y numeric(5,2) DEFAULT 50.0,
    scatter_distance integer DEFAULT 200,
    rotation_angle integer DEFAULT 0,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.animated_furniture_items OWNER TO sri;

--
-- Name: TABLE animated_furniture_items; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.animated_furniture_items IS 'Stores PNG furniture items for interactive homepage banner';


--
-- Name: animated_furniture_items_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.animated_furniture_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.animated_furniture_items_id_seq OWNER TO sri;

--
-- Name: animated_furniture_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.animated_furniture_items_id_seq OWNED BY public.animated_furniture_items.id;


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


ALTER TABLE public.blog_comments_id_seq OWNER TO sri;

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
    CONSTRAINT blog_media_media_type_check CHECK (((media_type)::text = ANY (ARRAY[('image'::character varying)::text, ('video'::character varying)::text])))
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


ALTER TABLE public.blog_media_id_seq OWNER TO sri;

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
    CONSTRAINT blog_reactions_reaction_type_check CHECK (((reaction_type)::text = ANY (ARRAY[('love'::character varying)::text, ('fire'::character varying)::text, ('happy'::character varying)::text, ('wow'::character varying)::text, ('clap'::character varying)::text, ('heart'::character varying)::text])))
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


ALTER TABLE public.blog_reactions_id_seq OWNER TO sri;

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


ALTER TABLE public.cart_id_seq OWNER TO sri;

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


ALTER TABLE public.categories_id_seq OWNER TO postgres;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: category_discounts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.category_discounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.category_discounts_id_seq OWNER TO postgres;

--
-- Name: category_discounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.category_discounts_id_seq OWNED BY public.category_discounts.id;


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
    coupon_code character varying(50),
    usage_type character varying(20) DEFAULT 'order'::character varying,
    CONSTRAINT coupon_usage_usage_type_check CHECK (((usage_type)::text = ANY (ARRAY[('order'::character varying)::text, ('wallet'::character varying)::text])))
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


ALTER TABLE public.coupon_usage_id_seq OWNER TO sri;

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
    coupon_type character varying(20) DEFAULT 'order'::character varying,
    expiry_type character varying(20) DEFAULT 'expiry'::character varying,
    CONSTRAINT coupons_coupon_type_check CHECK (((coupon_type)::text = ANY (ARRAY[('order'::character varying)::text, ('wallet'::character varying)::text, ('both'::character varying)::text]))),
    CONSTRAINT coupons_discount_type_check CHECK (((discount_type)::text = ANY (ARRAY[('percentage'::character varying)::text, ('fixed'::character varying)::text]))),
    CONSTRAINT coupons_expiry_type_check CHECK (((expiry_type)::text = ANY (ARRAY[('expiry'::character varying)::text, ('non_expiry'::character varying)::text])))
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


ALTER TABLE public.coupons_id_seq OWNER TO sri;

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


ALTER TABLE public.customer_blogs_id_seq OWNER TO sri;

--
-- Name: customer_blogs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.customer_blogs_id_seq OWNED BY public.customer_blogs.id;


--
-- Name: customer_inquiries; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.customer_inquiries (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    phone character varying(20) NOT NULL,
    setup_type character varying(100) NOT NULL,
    setup_type_other text,
    budget_range character varying(50) NOT NULL,
    quantity_scale character varying(50) NOT NULL,
    timeline character varying(50) NOT NULL,
    additional_requirements text,
    layout_photo character varying(500),
    reference_images text,
    preferred_contact_time character varying(100),
    wants_consultation boolean DEFAULT false,
    status character varying(50) DEFAULT 'new'::character varying,
    admin_notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    user_id integer
);


ALTER TABLE public.customer_inquiries OWNER TO sri;

--
-- Name: customer_inquiries_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.customer_inquiries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.customer_inquiries_id_seq OWNER TO sri;

--
-- Name: customer_inquiries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.customer_inquiries_id_seq OWNED BY public.customer_inquiries.id;


--
-- Name: deal_campaigns_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.deal_campaigns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.deal_campaigns_id_seq OWNER TO postgres;

--
-- Name: deal_campaigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.deal_campaigns_id_seq OWNED BY public.deal_campaigns.id;


--
-- Name: default_items; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.default_items (
    id integer NOT NULL,
    item_name character varying(100) NOT NULL,
    item_slug character varying(100) NOT NULL,
    icon_emoji character varying(10) DEFAULT '📦'::character varying,
    icon_image character varying(500),
    default_price numeric(10,2) DEFAULT 0,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    has_length boolean DEFAULT false,
    has_breadth boolean DEFAULT false,
    has_height boolean DEFAULT false
);


ALTER TABLE public.default_items OWNER TO sri;

--
-- Name: TABLE default_items; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.default_items IS 'Master table for all available items that can be added to lead designs';


--
-- Name: COLUMN default_items.item_slug; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.default_items.item_slug IS 'URL-friendly identifier used in code';


--
-- Name: COLUMN default_items.icon_emoji; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.default_items.icon_emoji IS 'Emoji icon displayed if no image uploaded';


--
-- Name: COLUMN default_items.icon_image; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.default_items.icon_image IS 'Path to uploaded icon image (relative to static folder)';


--
-- Name: COLUMN default_items.description; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.default_items.description IS 'Item description for admin reference';


--
-- Name: COLUMN default_items.display_order; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.default_items.display_order IS 'Order in which items appear in UI';


--
-- Name: COLUMN default_items.is_active; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.default_items.is_active IS 'Whether item is available for selection';


--
-- Name: COLUMN default_items.has_length; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.default_items.has_length IS 'Whether this item should capture a length dimension';


--
-- Name: COLUMN default_items.has_breadth; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.default_items.has_breadth IS 'Whether this item should capture a breadth/width dimension';


--
-- Name: COLUMN default_items.has_height; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.default_items.has_height IS 'Whether this item should capture a height dimension';


--
-- Name: default_items_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.default_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.default_items_id_seq OWNER TO sri;

--
-- Name: default_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.default_items_id_seq OWNED BY public.default_items.id;


--
-- Name: design_custom_fields; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.design_custom_fields (
    id integer NOT NULL,
    design_id integer,
    field_name character varying(255) NOT NULL,
    field_value text,
    field_price numeric(10,2) DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.design_custom_fields OWNER TO sri;

--
-- Name: design_custom_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.design_custom_fields_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.design_custom_fields_id_seq OWNER TO sri;

--
-- Name: design_custom_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.design_custom_fields_id_seq OWNED BY public.design_custom_fields.id;


--
-- Name: design_items; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.design_items (
    id integer NOT NULL,
    design_id integer,
    table_enabled boolean DEFAULT false,
    table_type character varying(50),
    table_size character varying(50),
    table_with_storage boolean DEFAULT false,
    table_price numeric(10,2) DEFAULT 0,
    chair_enabled boolean DEFAULT false,
    chair_type character varying(50),
    chair_quantity integer DEFAULT 1,
    chair_price numeric(10,2) DEFAULT 0,
    mini_plants_enabled boolean DEFAULT false,
    mini_plants_count integer DEFAULT 0,
    mini_plants_price numeric(10,2) DEFAULT 0,
    big_plants_enabled boolean DEFAULT false,
    big_plants_count integer DEFAULT 0,
    big_plants_price numeric(10,2) DEFAULT 0,
    artefacts_enabled boolean DEFAULT false,
    artefacts_count integer DEFAULT 0,
    artefacts_price numeric(10,2) DEFAULT 0,
    frames_enabled boolean DEFAULT false,
    frames_mini_count integer DEFAULT 0,
    frames_medium_count integer DEFAULT 0,
    frames_large_count integer DEFAULT 0,
    frames_price numeric(10,2) DEFAULT 0,
    table_lamp_enabled boolean DEFAULT false,
    table_lamp_type character varying(50),
    table_lamp_price numeric(10,2) DEFAULT 0,
    multisocket_enabled boolean DEFAULT false,
    multisocket_price numeric(10,2) DEFAULT 1200,
    cable_organiser_enabled boolean DEFAULT false,
    cable_organiser_price numeric(10,2) DEFAULT 1200,
    deskmat_enabled boolean DEFAULT false,
    deskmat_price numeric(10,2) DEFAULT 1000,
    floor_mat_enabled boolean DEFAULT false,
    floor_mat_size character varying(50),
    floor_mat_price numeric(10,2) DEFAULT 0,
    profile_light_enabled boolean DEFAULT false,
    profile_light_feet numeric(5,2) DEFAULT 0,
    profile_light_price numeric(10,2) DEFAULT 0,
    clock_enabled boolean DEFAULT false,
    clock_price numeric(10,2) DEFAULT 1000,
    pegboard_enabled boolean DEFAULT false,
    pegboard_size character varying(50),
    pegboard_price numeric(10,2) DEFAULT 0,
    subtotal numeric(10,2) DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.design_items OWNER TO sri;

--
-- Name: design_items_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.design_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.design_items_id_seq OWNER TO sri;

--
-- Name: design_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.design_items_id_seq OWNED BY public.design_items.id;


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


ALTER TABLE public.discount_id_seq OWNER TO sri;

--
-- Name: discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.discount_id_seq OWNED BY public.discount.id;


--
-- Name: error_alerts; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.error_alerts (
    id integer NOT NULL,
    error_type character varying(100) NOT NULL,
    error_message text NOT NULL,
    stack_trace text,
    endpoint character varying(500),
    request_data jsonb,
    user_id integer,
    ip_address character varying(45),
    severity character varying(20) DEFAULT 'medium'::character varying,
    is_notified boolean DEFAULT false,
    notification_sent_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.error_alerts OWNER TO sri;

--
-- Name: TABLE error_alerts; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.error_alerts IS 'Stores application errors and alerts for monitoring';


--
-- Name: error_alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.error_alerts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.error_alerts_id_seq OWNER TO sri;

--
-- Name: error_alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.error_alerts_id_seq OWNED BY public.error_alerts.id;


--
-- Name: global_discount_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.global_discount_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.global_discount_id_seq OWNER TO postgres;

--
-- Name: global_discount_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.global_discount_id_seq OWNED BY public.global_discount.id;


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


ALTER TABLE public.gst_settings_id_seq OWNER TO sri;

--
-- Name: gst_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.gst_settings_id_seq OWNED BY public.gst_settings.id;


--
-- Name: homepage_banner; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.homepage_banner (
    id integer NOT NULL,
    banner_image character varying(500) NOT NULL,
    title character varying(200) DEFAULT 'Premium Home Office Setup'::character varying,
    subtitle text DEFAULT 'Transform your workspace with complete desk setups designed for productivity, comfort, and style. From WFH to executive offices, we deliver ready-to-use solutions.'::text,
    button_text character varying(100) DEFAULT 'Get Started'::character varying,
    button_link character varying(200) DEFAULT '/products'::character varying,
    video_link character varying(300) DEFAULT 'https://youtu.be/U7gP16TXE8w?si=s5nXSpjALnLEEx81'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    display_order integer DEFAULT 0,
    slide_duration integer DEFAULT 5000,
    enable_carousel boolean DEFAULT false
);


ALTER TABLE public.homepage_banner OWNER TO sri;

--
-- Name: homepage_banner_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.homepage_banner_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.homepage_banner_id_seq OWNER TO sri;

--
-- Name: homepage_banner_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.homepage_banner_id_seq OWNED BY public.homepage_banner.id;


--
-- Name: homepage_carousel_images; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.homepage_carousel_images (
    id integer NOT NULL,
    image_url character varying(500) NOT NULL,
    title character varying(200),
    subtitle text,
    button_text character varying(100),
    button_link character varying(200),
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.homepage_carousel_images OWNER TO sri;

--
-- Name: TABLE homepage_carousel_images; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.homepage_carousel_images IS 'Stores multiple banner images for homepage carousel';


--
-- Name: COLUMN homepage_carousel_images.display_order; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.homepage_carousel_images.display_order IS 'Order in which images appear in carousel (0 = first)';


--
-- Name: homepage_carousel_images_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.homepage_carousel_images_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.homepage_carousel_images_id_seq OWNER TO sri;

--
-- Name: homepage_carousel_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.homepage_carousel_images_id_seq OWNED BY public.homepage_carousel_images.id;


--
-- Name: item_default_prices; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.item_default_prices (
    id integer NOT NULL,
    item_name character varying(100) NOT NULL,
    default_price numeric(10,2) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.item_default_prices OWNER TO sri;

--
-- Name: item_default_prices_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.item_default_prices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.item_default_prices_id_seq OWNER TO sri;

--
-- Name: item_default_prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.item_default_prices_id_seq OWNED BY public.item_default_prices.id;


--
-- Name: lead_designs; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.lead_designs (
    id integer NOT NULL,
    lead_id integer,
    design_name character varying(255) NOT NULL,
    design_image character varying(500),
    design_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    price numeric(10,2) DEFAULT 0,
    has_table boolean DEFAULT false,
    has_chair boolean DEFAULT false,
    has_plants boolean DEFAULT false,
    has_lighting boolean DEFAULT false,
    has_storage boolean DEFAULT false,
    has_accessories boolean DEFAULT false,
    table_details text,
    chair_details text,
    plants_details text,
    lighting_details text,
    storage_details text,
    accessories_details text,
    notes text,
    table_price numeric(10,2) DEFAULT 0,
    chair_price numeric(10,2) DEFAULT 0,
    plants_price numeric(10,2) DEFAULT 0,
    lighting_price numeric(10,2) DEFAULT 0,
    storage_price numeric(10,2) DEFAULT 0,
    accessories_price numeric(10,2) DEFAULT 0,
    discount_type character varying(20) DEFAULT 'none'::character varying,
    discount_value numeric(10,2) DEFAULT 0,
    subtotal numeric(10,2) DEFAULT 0,
    final_price numeric(10,2) DEFAULT 0,
    custom_items jsonb DEFAULT '[]'::jsonb,
    media_files jsonb DEFAULT '[]'::jsonb,
    table_quantity integer DEFAULT 1,
    chair_quantity integer DEFAULT 1,
    plants_quantity integer DEFAULT 1,
    lighting_quantity integer DEFAULT 1,
    storage_quantity integer DEFAULT 1,
    accessories_quantity integer DEFAULT 1,
    has_big_plants boolean DEFAULT false,
    big_plants_quantity integer DEFAULT 1,
    big_plants_price numeric(10,2) DEFAULT 0,
    big_plants_details text,
    has_mini_plants boolean DEFAULT false,
    mini_plants_quantity integer DEFAULT 1,
    mini_plants_price numeric(10,2) DEFAULT 0,
    mini_plants_details text,
    has_frames boolean DEFAULT false,
    frames_quantity integer DEFAULT 1,
    frames_price numeric(10,2) DEFAULT 0,
    frames_details text,
    has_wall_racks boolean DEFAULT false,
    wall_racks_quantity integer DEFAULT 1,
    wall_racks_price numeric(10,2) DEFAULT 0,
    wall_racks_details text,
    has_desk_mat boolean DEFAULT false,
    desk_mat_quantity integer DEFAULT 1,
    desk_mat_price numeric(10,2) DEFAULT 0,
    desk_mat_details text,
    has_dustbin boolean DEFAULT false,
    dustbin_quantity integer DEFAULT 1,
    dustbin_price numeric(10,2) DEFAULT 0,
    dustbin_details text,
    has_floor_mat boolean DEFAULT false,
    floor_mat_quantity integer DEFAULT 1,
    floor_mat_price numeric(10,2) DEFAULT 0,
    floor_mat_details text,
    has_keyboard boolean DEFAULT false,
    keyboard_quantity integer DEFAULT 1,
    keyboard_price numeric(10,2) DEFAULT 0,
    keyboard_details text,
    has_mouse boolean DEFAULT false,
    mouse_quantity integer DEFAULT 1,
    mouse_price numeric(10,2) DEFAULT 0,
    mouse_details text,
    has_paint boolean DEFAULT false,
    paint_quantity integer DEFAULT 1,
    paint_price numeric(10,2) DEFAULT 0,
    paint_details text,
    has_wardrobes boolean DEFAULT false,
    wardrobes_quantity integer DEFAULT 1,
    wardrobes_price numeric(10,2) DEFAULT 0,
    wardrobes_details text,
    has_deskmat boolean DEFAULT false,
    deskmat_quantity integer DEFAULT 1,
    deskmat_price numeric(10,2) DEFAULT 0,
    deskmat_details text,
    has_carpet boolean DEFAULT false,
    carpet_quantity integer DEFAULT 0,
    carpet_price numeric(10,2) DEFAULT 0,
    carpet_details text,
    has_curtains boolean DEFAULT false,
    curtains_quantity integer DEFAULT 0,
    curtains_price numeric(10,2) DEFAULT 0,
    curtains_details text,
    has_wall_art boolean DEFAULT false,
    wall_art_quantity integer DEFAULT 0,
    wall_art_price numeric(10,2) DEFAULT 0,
    wall_art_details text,
    has_desk_organizer boolean DEFAULT false,
    desk_organizer_quantity integer DEFAULT 0,
    desk_organizer_price numeric(10,2) DEFAULT 0,
    desk_organizer_details text,
    has_monitor_stand boolean DEFAULT false,
    monitor_stand_quantity integer DEFAULT 0,
    monitor_stand_price numeric(10,2) DEFAULT 0,
    monitor_stand_details text,
    has_cable_management boolean DEFAULT false,
    cable_management_quantity integer DEFAULT 0,
    cable_management_price numeric(10,2) DEFAULT 0,
    cable_management_details text,
    has_footrest boolean DEFAULT false,
    footrest_quantity integer DEFAULT 0,
    footrest_price numeric(10,2) DEFAULT 0,
    footrest_details text,
    has_monitor boolean DEFAULT false,
    monitor_quantity integer DEFAULT 0,
    monitor_price numeric(10,2) DEFAULT 0,
    monitor_details text,
    has_laptop_stand boolean DEFAULT false,
    laptop_stand_quantity integer DEFAULT 0,
    laptop_stand_price numeric(10,2) DEFAULT 0,
    laptop_stand_details text,
    has_headphone_stand boolean DEFAULT false,
    headphone_stand_quantity integer DEFAULT 0,
    headphone_stand_price numeric(10,2) DEFAULT 0,
    headphone_stand_details text,
    has_whiteboard boolean DEFAULT false,
    whiteboard_quantity integer DEFAULT 0,
    whiteboard_price numeric(10,2) DEFAULT 0,
    whiteboard_details text,
    has_bookshelf boolean DEFAULT false,
    bookshelf_quantity integer DEFAULT 0,
    bookshelf_price numeric(10,2) DEFAULT 0,
    bookshelf_details text,
    has_trash_bin boolean DEFAULT false,
    trash_bin_quantity integer DEFAULT 0,
    trash_bin_price numeric(10,2) DEFAULT 0,
    trash_bin_details text,
    has_desk_lamp boolean DEFAULT false,
    desk_lamp_quantity integer DEFAULT 0,
    desk_lamp_price numeric(10,2) DEFAULT 0,
    desk_lamp_details text,
    has_pen_holder boolean DEFAULT false,
    pen_holder_quantity integer DEFAULT 0,
    pen_holder_price numeric(10,2) DEFAULT 0,
    pen_holder_details text,
    has_laptop_holder boolean DEFAULT false,
    laptop_holder_quantity integer DEFAULT 0,
    laptop_holder_price numeric(10,2) DEFAULT 0,
    laptop_holder_details text,
    chair_headrest character varying(20) DEFAULT 'with_headrest'::character varying,
    has_profile_lighting boolean DEFAULT false,
    profile_lighting_quantity integer DEFAULT 1,
    profile_lighting_price numeric(10,2) DEFAULT 0,
    profile_lighting_details text,
    table_length_ft numeric(5,1) DEFAULT 4.0,
    table_width_ft numeric(5,1) DEFAULT 2.0,
    table_height_inch numeric(5,1) DEFAULT 29.0,
    storage_length_ft numeric(5,1) DEFAULT 3.0,
    storage_width_ft numeric(5,1) DEFAULT 1.5,
    storage_height_ft numeric(5,1) DEFAULT 6.0,
    lighting_length_ft numeric(5,1) DEFAULT 10.0,
    profile_lighting_length_ft numeric(5,1) DEFAULT 10.0,
    frames_size_ft character varying(50) DEFAULT '2x3'::character varying,
    wall_racks_length_ft numeric(5,1) DEFAULT 4.0,
    has_multi_socket boolean DEFAULT false,
    multi_socket_quantity integer DEFAULT 1,
    multi_socket_price numeric(10,2) DEFAULT 0,
    multi_socket_details text,
    big_plants_height_ft numeric(5,1) DEFAULT 3.0,
    mini_plants_height_ft numeric(5,1) DEFAULT 1.0,
    wardrobes_length_ft numeric(10,2) DEFAULT 6.0,
    wardrobes_width_ft numeric(10,2) DEFAULT 2.0,
    wardrobes_height_ft numeric(10,2) DEFAULT 7.0,
    desk_mat_length character varying(50),
    desk_mat_height character varying(50)
);


ALTER TABLE public.lead_designs OWNER TO sri;

--
-- Name: COLUMN lead_designs.table_price; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.table_price IS 'Price for desk/table item';


--
-- Name: COLUMN lead_designs.chair_price; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.chair_price IS 'Price for chair item';


--
-- Name: COLUMN lead_designs.plants_price; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.plants_price IS 'Price for plants & decor item';


--
-- Name: COLUMN lead_designs.lighting_price; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.lighting_price IS 'Price for lighting item';


--
-- Name: COLUMN lead_designs.storage_price; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.storage_price IS 'Price for storage solutions item';


--
-- Name: COLUMN lead_designs.accessories_price; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.accessories_price IS 'Price for accessories item';


--
-- Name: COLUMN lead_designs.discount_type; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.discount_type IS 'Type of discount: none, percentage, or fixed';


--
-- Name: COLUMN lead_designs.discount_value; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.discount_value IS 'Discount value (percentage or fixed amount)';


--
-- Name: COLUMN lead_designs.subtotal; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.subtotal IS 'Total before discount';


--
-- Name: COLUMN lead_designs.final_price; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.final_price IS 'Final price after discount';


--
-- Name: COLUMN lead_designs.media_files; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.media_files IS 'JSONB array of media files with validation: max 5 files (2 videos, 3 images), 5MB images, 50MB videos';


--
-- Name: COLUMN lead_designs.table_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.table_quantity IS 'Number of desks/tables';


--
-- Name: COLUMN lead_designs.chair_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.chair_quantity IS 'Number of chairs';


--
-- Name: COLUMN lead_designs.big_plants_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.big_plants_quantity IS 'Number of big plants';


--
-- Name: COLUMN lead_designs.mini_plants_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.mini_plants_quantity IS 'Number of mini plants';


--
-- Name: COLUMN lead_designs.frames_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.frames_quantity IS 'Number of frames';


--
-- Name: COLUMN lead_designs.wall_racks_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.wall_racks_quantity IS 'Number of wall racks';


--
-- Name: COLUMN lead_designs.desk_mat_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.desk_mat_quantity IS 'Number of desk mats';


--
-- Name: COLUMN lead_designs.dustbin_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.dustbin_quantity IS 'Number of dustbins';


--
-- Name: COLUMN lead_designs.floor_mat_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.floor_mat_quantity IS 'Number of floor mats';


--
-- Name: COLUMN lead_designs.keyboard_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.keyboard_quantity IS 'Number of keyboards';


--
-- Name: COLUMN lead_designs.mouse_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.mouse_quantity IS 'Number of mice';


--
-- Name: COLUMN lead_designs.paint_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.paint_quantity IS 'Paint quantity (liters/cans)';


--
-- Name: COLUMN lead_designs.wardrobes_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.wardrobes_quantity IS 'Number of wardrobes';


--
-- Name: COLUMN lead_designs.deskmat_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.deskmat_quantity IS 'Number of desk mats';


--
-- Name: COLUMN lead_designs.has_profile_lighting; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.has_profile_lighting IS 'Whether profile lighting is included in this design';


--
-- Name: COLUMN lead_designs.profile_lighting_quantity; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.profile_lighting_quantity IS 'Quantity of profile lighting units';


--
-- Name: COLUMN lead_designs.profile_lighting_price; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.profile_lighting_price IS 'Unit price for profile lighting';


--
-- Name: COLUMN lead_designs.profile_lighting_details; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.profile_lighting_details IS 'Additional details about profile lighting';


--
-- Name: COLUMN lead_designs.desk_mat_length; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.desk_mat_length IS 'Desk mat length/dimension text';


--
-- Name: COLUMN lead_designs.desk_mat_height; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.lead_designs.desk_mat_height IS 'Desk mat height/dimension text';


--
-- Name: lead_designs_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.lead_designs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lead_designs_id_seq OWNER TO sri;

--
-- Name: lead_designs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.lead_designs_id_seq OWNED BY public.lead_designs.id;


--
-- Name: leads; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.leads (
    id integer NOT NULL,
    customer_name character varying(255) NOT NULL,
    customer_email character varying(255),
    customer_phone character varying(20),
    project_name character varying(255),
    reference_image character varying(500),
    status character varying(50) DEFAULT 'draft'::character varying,
    discount_type character varying(20) DEFAULT 'none'::character varying,
    discount_value numeric(10,2) DEFAULT 0,
    notes text,
    share_token character varying(100),
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    location text,
    customer_rating integer,
    customer_feedback text,
    feedback_submitted_at timestamp without time zone,
    valid_until timestamp without time zone,
    is_expired boolean DEFAULT false,
    CONSTRAINT leads_customer_rating_check CHECK (((customer_rating >= 0) AND (customer_rating <= 5)))
);


ALTER TABLE public.leads OWNER TO sri;

--
-- Name: COLUMN leads.location; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.leads.location IS 'Customer location/address for delivery and installation';


--
-- Name: COLUMN leads.customer_rating; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.leads.customer_rating IS 'Customer rating for the quotation (1-5 stars)';


--
-- Name: COLUMN leads.customer_feedback; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.leads.customer_feedback IS 'Customer feedback or questions about the quotation';


--
-- Name: COLUMN leads.feedback_submitted_at; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.leads.feedback_submitted_at IS 'Timestamp when customer submitted feedback';


--
-- Name: COLUMN leads.valid_until; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.leads.valid_until IS 'Quotation expiry date/time - default 7 days from creation';


--
-- Name: COLUMN leads.is_expired; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.leads.is_expired IS 'Flag to mark quotation as expired - can be manually set by admin';


--
-- Name: leads_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.leads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.leads_id_seq OWNER TO sri;

--
-- Name: leads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.leads_id_seq OWNED BY public.leads.id;


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


ALTER TABLE public.order_items_id_seq OWNER TO sri;

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


ALTER TABLE public.orders_id_seq OWNER TO sri;

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


ALTER TABLE public.otp_verifications_id_seq OWNER TO sri;

--
-- Name: otp_verifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.otp_verifications_id_seq OWNED BY public.otp_verifications.id;


--
-- Name: page_views; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.page_views (
    id integer NOT NULL,
    visitor_id character varying(255) NOT NULL,
    page_url text NOT NULL,
    page_title character varying(500),
    referrer text,
    time_spent integer DEFAULT 0,
    session_id character varying(255),
    ip_address character varying(45),
    user_agent text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.page_views OWNER TO sri;

--
-- Name: TABLE page_views; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.page_views IS 'Stores individual page view events with detailed analytics';


--
-- Name: page_views_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.page_views_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.page_views_id_seq OWNER TO sri;

--
-- Name: page_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.page_views_id_seq OWNED BY public.page_views.id;


--
-- Name: pricing_rules; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.pricing_rules (
    id integer NOT NULL,
    item_category character varying(100) NOT NULL,
    item_type character varying(100),
    base_price numeric(10,2) NOT NULL,
    price_per_unit numeric(10,2),
    description text,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.pricing_rules OWNER TO sri;

--
-- Name: pricing_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.pricing_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pricing_rules_id_seq OWNER TO sri;

--
-- Name: pricing_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.pricing_rules_id_seq OWNED BY public.pricing_rules.id;


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


ALTER TABLE public.product_reviews_id_seq OWNER TO sri;

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


ALTER TABLE public.product_sub_images_id_seq OWNER TO sri;

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
    category_id integer,
    original_price numeric(10,2) DEFAULT NULL::numeric,
    discount_percent numeric(5,2) DEFAULT 0.00,
    discounted_price numeric(10,2) DEFAULT NULL::numeric
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


ALTER TABLE public.products_id_seq OWNER TO sri;

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


ALTER TABLE public.referral_coupons_id_seq OWNER TO sri;

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


ALTER TABLE public.review_helpful_votes_id_seq OWNER TO sri;

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
    CONSTRAINT review_media_media_type_check CHECK (((media_type)::text = ANY (ARRAY[('image'::character varying)::text, ('video'::character varying)::text])))
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


ALTER TABLE public.review_media_id_seq OWNER TO postgres;

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


ALTER TABLE public.reviews_id_seq OWNER TO sri;

--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- Name: room_visualizations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.room_visualizations (
    id integer NOT NULL,
    user_id integer NOT NULL,
    product_id integer NOT NULL,
    room_image_url character varying(500) NOT NULL,
    result_image_url character varying(500) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.room_visualizations OWNER TO postgres;

--
-- Name: TABLE room_visualizations; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.room_visualizations IS 'Stores AI-generated room visualizations for products';


--
-- Name: COLUMN room_visualizations.user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.room_visualizations.user_id IS 'User who created the visualization';


--
-- Name: COLUMN room_visualizations.product_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.room_visualizations.product_id IS 'Product being visualized';


--
-- Name: COLUMN room_visualizations.room_image_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.room_visualizations.room_image_url IS 'Path to uploaded room image';


--
-- Name: COLUMN room_visualizations.result_image_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.room_visualizations.result_image_url IS 'Path to AI-generated result image';


--
-- Name: room_visualizations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.room_visualizations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.room_visualizations_id_seq OWNER TO postgres;

--
-- Name: room_visualizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.room_visualizations_id_seq OWNED BY public.room_visualizations.id;


--
-- Name: system_health_logs; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.system_health_logs (
    id integer NOT NULL,
    check_type character varying(100) NOT NULL,
    status character varying(50) NOT NULL,
    error_message text,
    response_time integer,
    endpoint character varying(500),
    details jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.system_health_logs OWNER TO sri;

--
-- Name: TABLE system_health_logs; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.system_health_logs IS 'Stores system health check results';


--
-- Name: system_health_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.system_health_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.system_health_logs_id_seq OWNER TO sri;

--
-- Name: system_health_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.system_health_logs_id_seq OWNED BY public.system_health_logs.id;


--
-- Name: user_workspace_items; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.user_workspace_items (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(255) NOT NULL,
    image_data text NOT NULL,
    category character varying(100) DEFAULT 'custom'::character varying,
    width integer NOT NULL,
    height integer NOT NULL,
    position_x numeric(10,2) DEFAULT 50.00,
    position_y numeric(10,2) DEFAULT 50.00,
    rotation_angle numeric(10,2) DEFAULT 0.00,
    scale_factor numeric(10,2) DEFAULT 1.00,
    z_index integer DEFAULT 100,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_workspace_items OWNER TO sri;

--
-- Name: TABLE user_workspace_items; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.user_workspace_items IS 'Stores user-specific furniture items for personalized workspace layouts';


--
-- Name: COLUMN user_workspace_items.image_data; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.user_workspace_items.image_data IS 'Base64 encoded PNG image data';


--
-- Name: COLUMN user_workspace_items.position_x; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.user_workspace_items.position_x IS 'X position as percentage (0-100)';


--
-- Name: COLUMN user_workspace_items.position_y; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.user_workspace_items.position_y IS 'Y position as percentage (0-100)';


--
-- Name: user_workspace_items_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.user_workspace_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_workspace_items_id_seq OWNER TO sri;

--
-- Name: user_workspace_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.user_workspace_items_id_seq OWNED BY public.user_workspace_items.id;


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
    first_order_completed boolean DEFAULT false,
    is_admin boolean DEFAULT false,
    admin_level integer DEFAULT 2
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
-- Name: COLUMN users.admin_level; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON COLUMN public.users.admin_level IS 'Admin permission level: 1=Super Admin (full access), 2=Regular Admin (no delete)';


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


ALTER TABLE public.users_id_seq OWNER TO sri;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: visitor_tracking; Type: TABLE; Schema: public; Owner: sri
--

CREATE TABLE public.visitor_tracking (
    id integer NOT NULL,
    visitor_id character varying(255) NOT NULL,
    ip_address character varying(45),
    user_agent text,
    country character varying(100),
    city character varying(100),
    region character varying(100),
    browser character varying(100),
    os character varying(100),
    device_type character varying(50),
    referrer text,
    landing_page text,
    first_visit timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_visit timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    total_visits integer DEFAULT 1,
    total_page_views integer DEFAULT 1,
    is_registered boolean DEFAULT false,
    user_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.visitor_tracking OWNER TO sri;

--
-- Name: TABLE visitor_tracking; Type: COMMENT; Schema: public; Owner: sri
--

COMMENT ON TABLE public.visitor_tracking IS 'Stores unique visitor information and tracking data';


--
-- Name: visitor_tracking_id_seq; Type: SEQUENCE; Schema: public; Owner: sri
--

CREATE SEQUENCE public.visitor_tracking_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.visitor_tracking_id_seq OWNER TO sri;

--
-- Name: visitor_tracking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sri
--

ALTER SEQUENCE public.visitor_tracking_id_seq OWNED BY public.visitor_tracking.id;


--
-- Name: visualization_stats; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.visualization_stats AS
 SELECT p.id AS product_id,
    p.name AS product_name,
    p.category,
    count(v.id) AS total_visualizations,
    count(DISTINCT v.user_id) AS unique_users,
    max(v.created_at) AS last_visualization
   FROM (public.products p
     LEFT JOIN public.room_visualizations v ON ((p.id = v.product_id)))
  GROUP BY p.id, p.name, p.category;


ALTER TABLE public.visualization_stats OWNER TO postgres;

--
-- Name: VIEW visualization_stats; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.visualization_stats IS 'Statistics about product visualizations';


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


ALTER TABLE public.wallet_summary OWNER TO sri;

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


ALTER TABLE public.wallet_transactions_id_seq OWNER TO sri;

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


ALTER TABLE public.wallets_id_seq OWNER TO sri;

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
-- Name: animated_banner_settings id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.animated_banner_settings ALTER COLUMN id SET DEFAULT nextval('public.animated_banner_settings_id_seq'::regclass);


--
-- Name: animated_furniture_items id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.animated_furniture_items ALTER COLUMN id SET DEFAULT nextval('public.animated_furniture_items_id_seq'::regclass);


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
-- Name: category_discounts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_discounts ALTER COLUMN id SET DEFAULT nextval('public.category_discounts_id_seq'::regclass);


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
-- Name: customer_inquiries id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.customer_inquiries ALTER COLUMN id SET DEFAULT nextval('public.customer_inquiries_id_seq'::regclass);


--
-- Name: deal_campaigns id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.deal_campaigns ALTER COLUMN id SET DEFAULT nextval('public.deal_campaigns_id_seq'::regclass);


--
-- Name: default_items id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.default_items ALTER COLUMN id SET DEFAULT nextval('public.default_items_id_seq'::regclass);


--
-- Name: design_custom_fields id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.design_custom_fields ALTER COLUMN id SET DEFAULT nextval('public.design_custom_fields_id_seq'::regclass);


--
-- Name: design_items id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.design_items ALTER COLUMN id SET DEFAULT nextval('public.design_items_id_seq'::regclass);


--
-- Name: discount id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.discount ALTER COLUMN id SET DEFAULT nextval('public.discount_id_seq'::regclass);


--
-- Name: error_alerts id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.error_alerts ALTER COLUMN id SET DEFAULT nextval('public.error_alerts_id_seq'::regclass);


--
-- Name: global_discount id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.global_discount ALTER COLUMN id SET DEFAULT nextval('public.global_discount_id_seq'::regclass);


--
-- Name: gst_settings id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.gst_settings ALTER COLUMN id SET DEFAULT nextval('public.gst_settings_id_seq'::regclass);


--
-- Name: homepage_banner id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.homepage_banner ALTER COLUMN id SET DEFAULT nextval('public.homepage_banner_id_seq'::regclass);


--
-- Name: homepage_carousel_images id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.homepage_carousel_images ALTER COLUMN id SET DEFAULT nextval('public.homepage_carousel_images_id_seq'::regclass);


--
-- Name: item_default_prices id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.item_default_prices ALTER COLUMN id SET DEFAULT nextval('public.item_default_prices_id_seq'::regclass);


--
-- Name: lead_designs id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.lead_designs ALTER COLUMN id SET DEFAULT nextval('public.lead_designs_id_seq'::regclass);


--
-- Name: leads id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.leads ALTER COLUMN id SET DEFAULT nextval('public.leads_id_seq'::regclass);


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
-- Name: page_views id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.page_views ALTER COLUMN id SET DEFAULT nextval('public.page_views_id_seq'::regclass);


--
-- Name: pricing_rules id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.pricing_rules ALTER COLUMN id SET DEFAULT nextval('public.pricing_rules_id_seq'::regclass);


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
-- Name: room_visualizations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_visualizations ALTER COLUMN id SET DEFAULT nextval('public.room_visualizations_id_seq'::regclass);


--
-- Name: system_health_logs id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.system_health_logs ALTER COLUMN id SET DEFAULT nextval('public.system_health_logs_id_seq'::regclass);


--
-- Name: user_workspace_items id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.user_workspace_items ALTER COLUMN id SET DEFAULT nextval('public.user_workspace_items_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: visitor_tracking id; Type: DEFAULT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.visitor_tracking ALTER COLUMN id SET DEFAULT nextval('public.visitor_tracking_id_seq'::regclass);


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
-- Data for Name: animated_banner_settings; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.animated_banner_settings (id, is_enabled, scatter_duration, scatter_easing, allow_drag, snap_to_grid, grid_size, show_reset_button, background_color, updated_at) FROM stdin;
1	t	2000	ease-out	t	f	20	t	#f8f9fa	2026-05-08 22:01:39.675349
\.


--
-- Data for Name: animated_furniture_items; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.animated_furniture_items (id, name, image_path, category, width, height, initial_x, initial_y, scatter_distance, rotation_angle, display_order, is_active, created_at, updated_at) FROM stdin;
9	Floor Lamp	/static/images/furniture/lamp1.png	lamp	60	180	20.00	30.00	200	0	4	f	2026-05-08 22:09:04.29496	2026-05-09 08:18:20.815196
1	Modern Chair	/static/images/furniture/furniture_20260509_081943_chair.png	chair	120	140	30.00	50.00	200	0	1	t	2026-05-08 22:01:39.676823	2026-05-09 08:19:43.225514
6	Modern Chair	/static/images/furniture/chair1.png	chair	120	140	30.00	50.00	200	0	1	f	2026-05-08 22:09:04.29496	2026-05-09 08:20:10.046965
11	Modern Chair	/static/images/furniture/chair1.png	chair	120	140	30.00	50.00	200	0	1	f	2026-05-08 22:11:18.387881	2026-05-09 08:20:10.713778
2	Office Desk	images/furniture/desk.png	table	200	150	50.00	50.00	200	0	2	f	2026-05-08 22:01:39.676823	2026-05-09 08:20:11.37738
3	Indoor Plant	/static/images/furniture/plant1.png	plant	80	120	70.00	50.00	200	0	3	f	2026-05-08 22:01:39.676823	2026-05-09 08:20:12.863595
8	Indoor Plant	/static/images/furniture/plant1.png	plant	80	120	70.00	50.00	200	0	3	f	2026-05-08 22:09:04.29496	2026-05-09 08:20:13.533505
7	Office Desk	/static/images/furniture/desk1.png	table	200	150	50.00	50.00	200	0	2	f	2026-05-08 22:09:04.29496	2026-05-09 08:20:15.10735
13	Indoor Plant	/static/images/furniture/plant1.png	plant	80	120	70.00	50.00	200	0	3	f	2026-05-08 22:11:18.387881	2026-05-09 08:20:16.503674
4	Floor Lamp	/static/images/furniture/lamp1.png	lamp	60	180	20.00	30.00	200	0	4	f	2026-05-08 22:01:39.676823	2026-05-09 08:20:17.246763
14	Floor Lamp	/static/images/furniture/lamp1.png	lamp	60	180	20.00	30.00	200	0	4	f	2026-05-08 22:11:18.387881	2026-05-09 08:20:18.686927
15	Bookshelf	/static/images/furniture/shelf1.png	storage	150	200	80.00	40.00	200	0	5	f	2026-05-08 22:11:18.387881	2026-05-09 08:20:19.647873
10	Bookshelf	/static/images/furniture/shelf1.png	storage	150	200	80.00	40.00	200	0	5	f	2026-05-08 22:09:04.29496	2026-05-09 08:20:20.406865
5	Bookshelf	/static/images/furniture/shelf1.png	storage	150	200	80.00	40.00	200	0	5	f	2026-05-08 22:01:39.676823	2026-05-09 08:20:21.206755
12	Office Desk	/static/images/furniture/furniture_20260509_081957_table.png	table	200	150	50.00	50.00	200	0	2	t	2026-05-08 22:11:18.387881	2026-05-09 08:20:28.594647
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
99	35	25	1
101	36	31	1
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
-- Data for Name: category_discounts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.category_discounts (id, campaign_id, category_id, category_name, discount_percent, is_active, created_at, updated_at) FROM stdin;
1	1	1	Basic	5.00	t	2026-04-29 06:48:54.777451	2026-04-29 06:48:54.777451
2	2	1	Basic	5.00	t	2026-04-29 06:51:17.895923	2026-04-29 06:51:17.895923
3	3	1	Basic	5.00	t	2026-04-30 10:56:52.292506	2026-04-30 10:56:52.292506
\.


--
-- Data for Name: coupon_usage; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.coupon_usage (id, coupon_id, user_id, order_id, discount_applied, used_at, discount_amount, referrer_bonus_amount, coupon_code, usage_type) FROM stdin;
3	10	14	\N	1000.00	2026-04-28 20:01:26.807929	1000.00	0.00	GSPACES_DESKS_FOLLOW	wallet
4	10	34	\N	1000.00	2026-04-28 20:12:05.552178	1000.00	0.00	GSPACES_DESKS_FOLLOW	wallet
5	10	35	\N	1000.00	2026-04-28 20:19:33.163497	1000.00	0.00	GSPACES_DESKS_FOLLOW	wallet
\.


--
-- Data for Name: coupons; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.coupons (id, code, discount_type, discount_value, description, min_order_amount, max_discount_amount, is_active, usage_limit, times_used, valid_from, valid_until, created_at, created_by, user_id, is_personal, coupon_type, expiry_type) FROM stdin;
2	DEEWALIFEST	percentage	2.00	2% Diwali festival discount	0.00	\N	f	\N	0	2026-04-11 05:45:10.405668	\N	2026-04-11 05:45:10.405668	sri.chityala501@gmail.com	\N	f	order	expiry
1	NEWGSPACES	fixed	1000.00	1000 discount for new customers	0.00	\N	t	\N	0	2026-04-11 05:45:10.405668	\N	2026-04-11 05:45:10.405668	sri.chityala501@gmail.com	\N	f	order	expiry
4	SRI2026	fixed	5000.00		0.00	\N	f	\N	0	2026-04-15 08:14:34.387663	\N	2026-04-15 08:14:34.387663	srichityala501@gmail.com	\N	f	order	expiry
7	BONUS_GSPACES_FCC4	fixed	500.00	Personal coupon for gspaces	0.00	\N	t	\N	0	2026-04-18 14:52:25.891663	2026-07-17 14:52:25.893566	2026-04-18 14:52:25.891663	srichityala501@gmail.com	32	t	order	expiry
9	BONUS_GSPACES_MM8X	fixed	500.00	bonus	0.00	\N	t	\N	0	2026-04-18 15:21:16.973102	2026-07-17 15:21:17.853385	2026-04-18 15:21:16.973102	srichityala501@gmail.com	32	t	order	expiry
10	GSPACES_DESKS_FOLLOW	fixed	1000.00	₹1000 wallet bonus for Instagram followers	0.00	\N	t	\N	0	2026-04-26 15:26:56.044806	2026-05-26 15:53:09.963444	2026-04-26 15:26:56.044806	admin	\N	f	wallet	expiry
14	CUSTOM	fixed	10.00		0.00	\N	t	\N	0	2026-04-28 20:43:20.528323	2026-04-30 00:00:00	2026-04-28 20:43:20.528323	srichityala501@gmail.com	14	f	order	expiry
\.


--
-- Data for Name: customer_blogs; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.customer_blogs (id, user_id, title, content, views, created_at, updated_at, product_id) FROM stdin;
20	14	#basegreen Dream setup	<article style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">\n\n  <h2 style="color: #2c3e50;">A Clean &amp; Minimal Workspace with GSpaces</h2>\n\n  <p>\n    I wanted a workspace that feels clean, minimal, and distraction-free—and GSpaces delivered exactly that. \n    This setup is simple yet elegant, making it perfect for daily work and long productive hours.\n  </p>\n\n  <p>\n    The all-white desk gives a premium and modern look, while the ergonomic chair provides great comfort and support. \n    The soft lighting under the desk and behind adds a warm and relaxing vibe, especially during evening work sessions.\n  </p>\n\n  <p>\n    I really like the small details in this setup. The neatly placed shelf, tiny decor items, and plants add personality \n    without making the space feel crowded. Everything is well-organized, and the wide desk mat makes working more comfortable.\n  </p>\n\n  <p>\n    The plants on both sides bring a natural feel to the setup, making the environment fresh and lively. \n    It’s the kind of workspace where you can sit for hours without feeling stressed.\n  </p>\n\n  <p>\n    The experience with <strong>GSpaces</strong> was smooth from start to finish. They helped me choose the right design, \n    handled the setup professionally, and ensured everything was perfectly arranged.\n  </p>\n\n  <p>\n    If you prefer a neat and minimal workspace that still looks stylish, GSpaces is a great choice. \n    It’s not just about looks—it truly improves your focus and overall work experience.\n  </p>\n\n  <blockquote style="margin-top: 20px; padding: 10px 20px;">\n    “Minimal setup, maximum focus.”\n  </blockquote>\n\n</article>	32	2026-04-22 16:54:51.45978	2026-05-09 11:12:28.629772	7
24	15	How to Create Your Perfect Desk Setup	<h2>Start with the Basics</h2>\n<p>Creating a great workspace doesn't have to be complicated! Here's what you really need:</p>\n\n<h3>1. The Right Desk</h3>\n<p>Choose a desk that fits your space and gives you enough room for your essentials. Make sure it's at the right height - your elbows should be at 90 degrees when typing.</p>\n\n<h3>2. A Comfortable Chair</h3>\n<p>This is where you'll spend most of your time! Look for good back support and adjustable height. Your feet should rest flat on the floor.</p>\n\n<h3>3. Good Lighting</h3>\n<p>Natural light is best, but add a desk lamp for those late-night sessions. Position it to avoid screen glare.</p>\n\n<h3>4. Keep It Organized</h3>\n<p>Use cable organizers, desk drawers, or small boxes to keep things tidy. A clean desk = a clear mind!</p>\n\n<h3>5. Add Personal Touches</h3>\n<p>A small plant, your favorite mug, or inspiring photos make your space feel like yours.</p>\n\n<h2>Pro Tips</h2>\n<ul>\n<li>Position your monitor at arm's length</li>\n<li>Take breaks every hour to stretch</li>\n<li>Keep frequently used items within easy reach</li>\n<li>Invest in quality over quantity</li>\n</ul>\n\n<p>Remember, the perfect setup is one that works for YOU. Start simple and add what you need over time!</p>\n\n<p><strong>Visit GSpaces to explore our range of desks, chairs, and accessories!</strong></p>	1	2026-05-02 17:10:21.236665	2026-05-09 17:10:58.808425	\N
25	15	Why We Only Recommend Ergonomic Chairs	<h2>Your Health Matters</h2>\n<p>At GSpaces, we only sell ergonomic chairs. Why? Because we care about your long-term health and comfort!</p>\n\n<h3>What Makes a Chair Ergonomic?</h3>\n<p>An ergonomic chair supports your body's natural posture. Key features include:</p>\n<ul>\n<li><strong>Lumbar Support:</strong> Supports your lower back curve</li>\n<li><strong>Adjustable Height:</strong> Fits your body perfectly</li>\n<li><strong>Comfortable Seat:</strong> Right depth and cushioning</li>\n<li><strong>Armrests:</strong> Reduces shoulder tension</li>\n</ul>\n\n<h3>The Real Benefits</h3>\n<p><strong>Say Goodbye to Back Pain:</strong> Proper support prevents the aches that come from poor posture.</p>\n\n<p><strong>Work Longer, Feel Better:</strong> When you're comfortable, you can focus on what matters without constant discomfort.</p>\n\n<p><strong>Better Posture, Better Health:</strong> Good posture improves breathing, energy, and even confidence!</p>\n\n<h3>Is It Worth the Investment?</h3>\n<p>Think about it - you spend 8+ hours a day in your chair. That's more time than you spend in your bed! A good ergonomic chair is an investment in your health and productivity.</p>\n\n<h3>Our Promise</h3>\n<p>Every chair at GSpaces is tested for ergonomic quality. We don't sell anything we wouldn't use ourselves!</p>\n\n<p><strong>Come try our chairs in person - your back will thank you!</strong></p>	0	2026-05-05 17:10:21.236665	2026-05-05 17:10:21.236665	\N
\.


--
-- Data for Name: customer_inquiries; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.customer_inquiries (id, name, email, phone, setup_type, setup_type_other, budget_range, quantity_scale, timeline, additional_requirements, layout_photo, reference_images, preferred_contact_time, wants_consultation, status, admin_notes, created_at, updated_at, user_id) FROM stdin;
2	sreekanth ch	sri.chityala501@gmail.com	7075077384	wfh		under_25k	single	immediate		\N	\N	anytime	f	new	\N	2026-05-02 11:36:38.940671	2026-05-02 11:36:38.940671	14
3	sreekanth ch	sri.chityala501@gmail.com	7075077384	wfh		under_25k	single	immediate		img/inquiries/inquiry_1777722274_basic-2.png	["img/inquiries/inquiry_1777722274_basic-2.png"]	anytime	t	new	\N	2026-05-02 11:44:34.46492	2026-05-02 11:44:34.46492	14
4	test	test@test.com	1234567890	office		under_25k	single	immediate	vdxv	\N	\N	1234567890	f	new	\N	2026-05-08 17:01:08.652739	2026-05-08 17:01:08.652739	\N
5	sreekanth	sri.chityala501@gmail.com	7075077384	office		25k_50k	2_10	immediate	test	\N	\N		t	new	\N	2026-05-08 17:03:18.639252	2026-05-08 17:03:18.639252	14
6	test	test@test.com	1234567890	office		under_25k	single	immediate		\N	\N	10	f	new	\N	2026-05-08 17:04:06.972148	2026-05-08 17:04:06.972148	\N
\.


--
-- Data for Name: deal_campaigns; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.deal_campaigns (id, name, description, is_active, start_time, end_time, countdown_duration, banner_text, created_at, updated_at) FROM stdin;
1	Welcome Offer	Default campaign for new visitors	f	\N	\N	86400	Limited Time Offer - Exclusive Discounts on Premium Desk Setups	2026-04-29 06:36:15.501833	2026-04-29 06:50:31.344264
2	Deewali offer		f	2026-04-29 06:50:52.861957	2026-04-30 06:50:52.861947	86400	Limited Time Offer - Exclusive Discounts on Premium Desk Setups	2026-04-29 06:50:52.861136	2026-04-30 10:56:32.330003
3	Summer	Summer Deal is on	f	2026-04-30 10:56:32.349474	2026-05-10 10:56:32.34946	864000	Limited Time Offer - Exclusive Discounts on Premium Desk Setups	2026-04-30 10:56:32.330003	2026-05-09 17:39:13.380665
\.


--
-- Data for Name: default_items; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.default_items (id, item_name, item_slug, icon_emoji, icon_image, default_price, description, display_order, is_active, created_at, updated_at, has_length, has_breadth, has_height) FROM stdin;
2	Chair	chair	💺	\N	10000.00	Ergonomic office chair with lumbar support	2	t	2026-05-03 14:36:12.946242	2026-05-03 14:36:12.946242	f	f	f
3	Plants	plants	🌿	\N	500.00	Indoor plants for decoration	3	t	2026-05-03 14:36:12.946242	2026-05-03 14:36:12.946242	f	f	f
7	Accessories	accessories	🎨	\N	2000.00	Desk organizers and accessories	7	t	2026-05-03 14:36:12.946242	2026-05-03 14:36:12.946242	f	f	f
13	Dustbin	dustbin	🗑️	\N	300.00	Desktop/floor waste bin	13	t	2026-05-03 14:36:12.946242	2026-05-03 14:36:12.946242	f	f	f
16	Mouse	mouse	🖱️	\N	800.00	Wireless/ergonomic mouse	16	t	2026-05-03 14:36:12.946242	2026-05-03 14:36:12.946242	f	f	f
17	Paint	paint	🎨	\N	5000.00	Wall painting	17	t	2026-05-03 14:36:12.946242	2026-05-03 14:36:12.946242	f	f	f
22	Monitor	monitor	🖥️	\N	15000.00	LED/LCD display monitor	22	t	2026-05-03 14:36:12.946242	2026-05-03 14:36:12.946242	f	f	f
24	Cable Management	cable_management	🔌	\N	800.00	Cable organizers and clips	24	t	2026-05-03 14:36:12.946242	2026-05-03 14:36:12.946242	f	f	f
25	Footrest	footrest	🦶	\N	1500.00	Ergonomic footrest	25	t	2026-05-03 14:36:12.946242	2026-05-03 14:36:12.946242	f	f	f
26	Headphone Stand	headphone_stand	🎧	\N	800.00	Desktop headphone holder	26	t	2026-05-03 14:36:12.946242	2026-05-03 14:36:12.946242	f	f	f
29	Monitor Stand	monitor_stand	🖥️	\N	2500.00	Adjustable monitor riser	29	t	2026-05-03 14:36:12.946242	2026-05-03 14:36:12.946242	f	f	f
30	Desk Organizer	desk_organizer	📋	\N	1500.00	Desktop organization system	30	t	2026-05-03 14:36:12.946242	2026-05-03 14:36:12.946242	f	f	f
5	Profile Lighting	profile_lighting	💡	\N	800.00	Profile/accent lighting	5	t	2026-05-03 14:36:12.946242	2026-05-06 19:31:51.854756	t	f	f
31	Multi Socket	socket		img/icons/icon_socket_20260503_164948_extension.png	1500.00	Multiple socket options 	1	t	2026-05-03 16:49:48.168556	2026-05-04 16:57:59.886472	f	f	f
11	Wall Racks	wall_racks	📚	img/icons/icon_wall_racks_20260503_170008_Screenshot_2026-05-03_at_10.29.23_PM.png	2000.00	Wall-mounted racks per rack	11	t	2026-05-03 14:36:12.946242	2026-05-06 19:31:51.854756	t	f	f
10	Frames	frames	🖼️	\N	800.00	Wall art frames per frame	10	t	2026-05-03 14:36:12.946242	2026-05-04 16:58:44.949609	f	f	f
14	Floor Mat	floor_mat	🧹	img/icons/icon_floor_mat_20260503_170630_Screenshot_2026-05-03_at_10.36.11_PM.png	500.00	Floor carpet/mat per sq ft	14	t	2026-05-03 14:36:12.946242	2026-05-04 16:59:24.260644	f	f	f
15	Keyboard	keyboard	⌨️	\N	1000.00	Mechanical/wireless keyboard	15	t	2026-05-03 14:36:12.946242	2026-05-04 16:59:40.182426	f	f	f
23	Laptop Stand	laptop_stand	💻	img/icons/icon_laptop_stand_20260503_170522_Screenshot_2026-05-03_at_10.35.00_PM.png	800.00	Adjustable laptop riser	23	t	2026-05-03 14:36:12.946242	2026-05-04 17:00:07.359227	f	f	f
27	Pegboard	whiteboard	📝	\N	3500.00	Wall-mounted whiteboard	27	t	2026-05-03 14:36:12.946242	2026-05-04 17:00:35.752959	f	f	f
28	Bookshelf	bookshelf	📚	\N	800.00	Wall/floor bookshelf	28	t	2026-05-03 14:36:12.946242	2026-05-04 17:01:09.789801	f	f	f
4	Rope Lighting	lighting	💡	\N	300.00	LED rope/ambient lighting per sq ft	4	t	2026-05-03 14:36:12.946242	2026-05-06 19:31:51.854756	t	f	f
35	Laptop Holder	laptop_holder	💻	\N	1200.00	Vertical laptop stand for space-saving desk organization	93	t	2026-05-04 17:46:02.682113	2026-05-04 18:13:19.320812	f	f	f
52	PVC Panel	pvc_wood_panel		img/icons/icon_pvc_wood_panel_20260505_171528_pvc_panel.png	1500.00	PVC Wood Panel for Wall Decors	0	t	2026-05-05 17:15:28.283553	2026-05-05 17:15:28.283553	f	f	f
53	Dark green panels	dark_green_panel		img/icons/icon_dark_green_panel_20260506_171717_dark_green_panel.png	1500.00	60Cm X 40Cm X 3Cm each panel size for wall decor	0	t	2026-05-06 17:17:17.642221	2026-05-06 17:17:33.197393	f	f	f
9	Mini Plants	mini_plants	🪴	\N	300.00	Small desktop plants per plant	9	t	2026-05-03 14:36:12.946242	2026-05-06 19:31:51.856168	f	f	t
8	Big Plants	big_plants	🌳	\N	1000.00	Large indoor plants per plant	8	t	2026-05-03 14:36:12.946242	2026-05-06 19:31:51.856168	f	f	t
19	Desk Lamp	desk_lamp	💡	img/icons/icon_desk_lamp_20260503_170218_table-lamp.png	800.00	LED desk lamp with adjustable brightness and color temperature	19	t	2026-05-03 14:36:12.946242	2026-05-04 18:13:19.31688	f	f	f
20	Pen Holder	pen_holder	✏️	img/icons/icon_pen_holder_20260503_170322_Screenshot_2026-05-03_at_10.33.03_PM.png	300.00	Wooden pen holder for organized desk storage	20	t	2026-05-03 14:36:12.946242	2026-05-04 18:13:19.319296	f	f	f
6	Storage	storage	🗄️	\N	5000.00	Cabinets, drawers, and shelves	6	t	2026-05-03 14:36:12.946242	2026-05-06 19:31:51.850421	t	t	t
18	Wardrobes	wardrobes	🚪	\N	1000.00	Storage wardrobes per sq ft	18	t	2026-05-03 14:36:12.946242	2026-05-06 19:31:51.850421	t	t	t
1	Desk Table	table		img/icons/icon_table_20260503_163612_desk.png	15000.00	Standard ergonomic desk table	1	t	2026-05-03 14:36:12.946242	2026-05-06 19:31:51.850421	t	t	t
12	Desk Mat	desk_mat	🎯	img/icons/icon_desk_mat_20260503_170116_Screenshot_2026-05-03_at_10.31.05_PM.png	800.00	Large desk pad/mat	12	t	2026-05-03 14:36:12.946242	2026-05-06 19:31:51.853242	t	t	f
\.


--
-- Data for Name: design_custom_fields; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.design_custom_fields (id, design_id, field_name, field_value, field_price, created_at) FROM stdin;
\.


--
-- Data for Name: design_items; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.design_items (id, design_id, table_enabled, table_type, table_size, table_with_storage, table_price, chair_enabled, chair_type, chair_quantity, chair_price, mini_plants_enabled, mini_plants_count, mini_plants_price, big_plants_enabled, big_plants_count, big_plants_price, artefacts_enabled, artefacts_count, artefacts_price, frames_enabled, frames_mini_count, frames_medium_count, frames_large_count, frames_price, table_lamp_enabled, table_lamp_type, table_lamp_price, multisocket_enabled, multisocket_price, cable_organiser_enabled, cable_organiser_price, deskmat_enabled, deskmat_price, floor_mat_enabled, floor_mat_size, floor_mat_price, profile_light_enabled, profile_light_feet, profile_light_price, clock_enabled, clock_price, pegboard_enabled, pegboard_size, pegboard_price, subtotal, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: discount; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.discount (id, discount_percent) FROM stdin;
58	10.00
\.


--
-- Data for Name: error_alerts; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.error_alerts (id, error_type, error_message, stack_trace, endpoint, request_data, user_id, ip_address, severity, is_notified, notification_sent_at, created_at) FROM stdin;
1	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:40:41.411465
2	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:41:12.61578
3	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:41:43.696617
4	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:42:14.555435
5	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:42:45.586928
6	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:43:16.212136
7	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:43:46.819556
8	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:44:17.563987
9	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:44:48.171168
10	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:45:18.819181
11	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:45:49.459557
12	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:46:21.474599
13	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:46:52.092053
14	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:47:22.806737
15	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:47:53.413171
16	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:48:14.990964
17	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:48:26.321684
18	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/about	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:48:29.83885
19	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:48:46.723312
20	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:49:17.814083
21	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:49:48.75649
22	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:50:19.730376
23	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/about	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:50:29.095755
24	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:50:50.739988
25	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/orders	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:51:06.863519
26	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/system-health	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:51:09.869543
27	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 06:51:21.978794
28	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:00:16.510448
29	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/system-health	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:00:34.325279
30	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:00:47.323734
31	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/	\N	14	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	medium	f	\N	2026-05-10 07:03:36.086403
32	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/my-workspace	\N	14	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	medium	f	\N	2026-05-10 07:04:08.428492
33	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/about	\N	14	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	medium	f	\N	2026-05-10 07:04:36.486952
34	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/corporate	\N	14	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	medium	f	\N	2026-05-10 07:05:26.285872
35	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/products	\N	14	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	medium	f	\N	2026-05-10 07:06:01.848865
36	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/product/28	\N	14	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	medium	f	\N	2026-05-10 07:06:17.227802
37	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/blogs	\N	14	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	medium	f	\N	2026-05-10 07:06:28.942523
38	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:06:58.866066
39	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/system-health	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:07:14.933208
40	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:07:29.891831
41	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:08:00.743505
42	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/system-health	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:08:15.848655
43	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:08:31.594989
44	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/profile	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:08:36.681247
45	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/logout	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:08:40.023543
46	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/	\N	\N	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:08:40.205049
47	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/profile	\N	\N	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:08:41.428211
48	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/login	\N	\N	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:08:41.612684
49	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/login	\N	\N	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:08:53.551577
50	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/visitors	\N	\N	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:09:02.588218
51	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/login	\N	\N	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:09:02.775201
52	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/google_signin	\N	\N	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:15:28.338754
53	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:15:28.651328
54	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/orders	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:15:30.41129
55	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users-management	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:15:33.549032
56	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/customers	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:15:33.808509
57	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:15:34.869266
58	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users/32/toggle-admin	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:15:52.317677
59	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:15:52.604659
60	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users-management	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:16:01.487119
61	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/customers	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:16:02.005477
62	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:16:03.526262
63	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users-management	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:16:40.982728
64	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/customers	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:16:41.241861
65	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/customers	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:16:43.225314
66	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/customers	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:16:44.445133
67	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:18:59.439365
68	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users-management	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:19:01.787776
69	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/customers	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:19:02.051816
70	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:19:02.809612
71	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users-management	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:23:02.304096
72	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/customers	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:23:03.060495
73	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/customers/14	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:23:09.058315
74	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users-management	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:23:12.299022
75	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/customers	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:23:12.554589
76	visitor_tracking	record "new" has no field "updated_at"\nCONTEXT:  PL/pgSQL assignment "NEW.updated_at = CURRENT_TIMESTAMP"\nPL/pgSQL function update_updated_at_column() line 3 at assignment\n	\N	/admin/users	\N	14	2406:b400:b4:b6a:49a0:f609:780d:1ad6	medium	f	\N	2026-05-10 07:23:19.889386
\.


--
-- Data for Name: global_discount; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.global_discount (id, campaign_id, discount_percent, is_active, priority, created_at, updated_at) FROM stdin;
1	1	5.00	f	0	2026-04-29 06:36:15.503392	2026-04-29 06:50:09.916113
\.


--
-- Data for Name: gst_settings; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.gst_settings (id, gst_enabled, gst_rate, gst_number, updated_at, updated_by, razorpay_key_gst, razorpay_secret_gst, razorpay_key_no_gst, razorpay_secret_no_gst) FROM stdin;
1	f	0.1800	36AORPG7724G1ZN	2026-04-19 13:02:02.750161	srichityala501@gmail.com	rzp_live_R6wg6buSedSnTV	xeBC7q5tEirlDg4y4Tc3JEc3	rzp_live_R6wg6buSedSnTV	xeBC7q5tEirlDg4y4Tc3JEc3
\.


--
-- Data for Name: homepage_banner; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.homepage_banner (id, banner_image, title, subtitle, button_text, button_link, video_link, is_active, created_at, updated_at, display_order, slide_duration, enable_carousel) FROM stdin;
1	/static/img/hero-bg.jpg	Premium Home Office Setup	Transform your workspace with complete desk setups designed for productivity, comfort, and style. From WFH to executive offices, we deliver ready-to-use solutions.	Get Started	/products	https://youtu.be/U7gP16TXE8w?si=s5nXSpjALnLEEx81	f	2026-05-08 21:11:12.482733	2026-05-08 21:11:12.482733	0	5000	f
2	/static/img/banner_20260508_211243_DSC06887_2.jpg	Premium Home Office Setup	Transform your workspace with complete desk setups designed for productivity, comfort, and style. From WFH to executive offices, we deliver ready-to-use solutions.	Get Started	/products	https://youtu.be/U7gP16TXE8w?si=s5nXSpjALnLEEx81	f	2026-05-08 21:12:43.463828	2026-05-08 21:12:43.463828	0	5000	f
3	/static/img/banner_20260508_211420_banner.jpg	Premium Home Office Setup	Transform your workspace with complete desk setups designed for productivity, comfort, and style. From WFH to executive offices, we deliver ready-to-use solutions.	Get Started	/products	https://youtu.be/U7gP16TXE8w?si=s5nXSpjALnLEEx81	t	2026-05-08 21:14:20.719841	2026-05-09 15:17:49.594391	0	5000	f
\.


--
-- Data for Name: homepage_carousel_images; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.homepage_carousel_images (id, image_url, title, subtitle, button_text, button_link, display_order, is_active, created_at, updated_at) FROM stdin;
1	/static/img/banner_20260508_211420_banner.jpg	Premium Home Office Setup	Transform your workspace with complete desk setups designed for productivity, comfort, and style. From WFH to executive offices, we deliver ready-to-use solutions.	Get Started	/products	1	f	2026-05-08 21:24:48.613057	2026-05-09 08:46:00.699271
3	/static/img/carousel_20260509_151521_DSC06887_2.jpg	Premium Home Office Setup	Transform your workspace with complete desk setups designed for productivity, comfort, and style. From WFH to executive offices, we deliver ready-to-use solutions.	Get Started	/products	2	t	2026-05-09 15:15:21.913434	2026-05-09 15:15:51.922042
2	/static/img/banner_20260508_211420_banner.jpg	Premium Home Office Setup	Transform your workspace with complete desk setups designed for productivity, comfort, and style. From WFH to executive offices, we deliver ready-to-use solutions.	Get Started	/products	0	f	2026-05-08 21:25:42.601145	2026-05-09 08:46:00.699271
\.


--
-- Data for Name: item_default_prices; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.item_default_prices (id, item_name, default_price, description, created_at, updated_at) FROM stdin;
5	accessories	600.00	Accessories - Desk organizers, pen holders (per item)	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
30	big_plants	1000.00	Big Plants - Large indoor plants (per plant)	2026-05-03 13:02:47.521112	2026-05-03 13:45:11.855998
20	bookshelf	10000.00	Bookshelf - Wall/floor bookshelf	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
11	cable_management	800.00	Cable Management - Cable organizers and clips	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
6	carpet	5000.00	Carpet - Floor mat/carpet	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
2	chair	12000.00	Office Chair - Ergonomic with lumbar support	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
7	curtains	4000.00	Curtains - Window curtains	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
22	desk_lamp	2500.00	Desk Lamp - LED desk lamp	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
12	desk_mat	1200.00	Desk Mat - Large desk pad/mat	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
9	desk_organizer	1500.00	Desk Organizer - Desktop organization	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
35	dustbin	500.00	Dustbin - Desktop/floor waste bin	2026-05-03 13:02:47.521112	2026-05-03 13:45:11.855998
36	floor_mat	500.00	Floor Mat - Floor carpet/mat (per sq ft)	2026-05-03 13:02:47.521112	2026-05-03 13:45:11.855998
13	footrest	1500.00	Footrest - Ergonomic footrest	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
32	frames	600.00	Frames - Wall art frames (per frame)	2026-05-03 13:02:47.521112	2026-05-03 13:45:11.855998
18	headphone_stand	800.00	Headphone Stand - Desktop headphone holder	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
14	keyboard	1000.00	Keyboard - Mechanical/wireless keyboard	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
24	laptop_holder	1800.00	Laptop Holder - Vertical laptop stand	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
17	laptop_stand	2000.00	Laptop Stand - Adjustable laptop riser	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
3	lighting	500.00	Lighting - LED desk/ambient lighting (per sq ft)	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
31	mini_plants	300.00	Mini Plants - Small desktop plants (per plant)	2026-05-03 13:02:47.521112	2026-05-03 13:45:11.855998
16	monitor	15000.00	Monitor - LED/LCD display monitor	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
10	monitor_stand	2500.00	Monitor Stand - Adjustable monitor riser	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
15	mouse	500.00	Mouse - Wireless/ergonomic mouse	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
39	paint	5000.00	Paint - Wall painting	2026-05-03 13:02:47.521112	2026-05-03 13:45:11.855998
23	pen_holder	500.00	Pen Holder - Desktop pen/pencil holder	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
4	storage	7000.00	Storage - Cabinets, drawers, shelves	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
1	table	15000.00	Desk Table - Standard ergonomic desk	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
21	trash_bin	500.00	Trash Bin - Desktop/floor waste bin	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
8	wall_art	3000.00	Wall Art - Paintings, posters	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
33	wall_racks	500.00	Wall Racks - Wall-mounted racks (per rack)	2026-05-03 13:02:47.521112	2026-05-03 13:45:11.855998
40	wardrobes	1000.00	Wardrobes - Storage wardrobes (per sq ft)	2026-05-03 13:02:47.521112	2026-05-03 13:45:11.855998
19	whiteboard	3500.00	Whiteboard - Wall-mounted whiteboard	2026-05-03 12:48:39.076227	2026-05-03 13:45:11.855998
\.


--
-- Data for Name: lead_designs; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.lead_designs (id, lead_id, design_name, design_image, design_order, created_at, price, has_table, has_chair, has_plants, has_lighting, has_storage, has_accessories, table_details, chair_details, plants_details, lighting_details, storage_details, accessories_details, notes, table_price, chair_price, plants_price, lighting_price, storage_price, accessories_price, discount_type, discount_value, subtotal, final_price, custom_items, media_files, table_quantity, chair_quantity, plants_quantity, lighting_quantity, storage_quantity, accessories_quantity, has_big_plants, big_plants_quantity, big_plants_price, big_plants_details, has_mini_plants, mini_plants_quantity, mini_plants_price, mini_plants_details, has_frames, frames_quantity, frames_price, frames_details, has_wall_racks, wall_racks_quantity, wall_racks_price, wall_racks_details, has_desk_mat, desk_mat_quantity, desk_mat_price, desk_mat_details, has_dustbin, dustbin_quantity, dustbin_price, dustbin_details, has_floor_mat, floor_mat_quantity, floor_mat_price, floor_mat_details, has_keyboard, keyboard_quantity, keyboard_price, keyboard_details, has_mouse, mouse_quantity, mouse_price, mouse_details, has_paint, paint_quantity, paint_price, paint_details, has_wardrobes, wardrobes_quantity, wardrobes_price, wardrobes_details, has_deskmat, deskmat_quantity, deskmat_price, deskmat_details, has_carpet, carpet_quantity, carpet_price, carpet_details, has_curtains, curtains_quantity, curtains_price, curtains_details, has_wall_art, wall_art_quantity, wall_art_price, wall_art_details, has_desk_organizer, desk_organizer_quantity, desk_organizer_price, desk_organizer_details, has_monitor_stand, monitor_stand_quantity, monitor_stand_price, monitor_stand_details, has_cable_management, cable_management_quantity, cable_management_price, cable_management_details, has_footrest, footrest_quantity, footrest_price, footrest_details, has_monitor, monitor_quantity, monitor_price, monitor_details, has_laptop_stand, laptop_stand_quantity, laptop_stand_price, laptop_stand_details, has_headphone_stand, headphone_stand_quantity, headphone_stand_price, headphone_stand_details, has_whiteboard, whiteboard_quantity, whiteboard_price, whiteboard_details, has_bookshelf, bookshelf_quantity, bookshelf_price, bookshelf_details, has_trash_bin, trash_bin_quantity, trash_bin_price, trash_bin_details, has_desk_lamp, desk_lamp_quantity, desk_lamp_price, desk_lamp_details, has_pen_holder, pen_holder_quantity, pen_holder_price, pen_holder_details, has_laptop_holder, laptop_holder_quantity, laptop_holder_price, laptop_holder_details, chair_headrest, has_profile_lighting, profile_lighting_quantity, profile_lighting_price, profile_lighting_details, table_length_ft, table_width_ft, table_height_inch, storage_length_ft, storage_width_ft, storage_height_ft, lighting_length_ft, profile_lighting_length_ft, frames_size_ft, wall_racks_length_ft, has_multi_socket, multi_socket_quantity, multi_socket_price, multi_socket_details, big_plants_height_ft, mini_plants_height_ft, wardrobes_length_ft, wardrobes_width_ft, wardrobes_height_ft, desk_mat_length, desk_mat_height) FROM stdin;
14	9	GreenNest Studio	img/leads/media/media_20260506_192614_0_daytime.png	2	2026-05-06 19:26:14.335017	39092.50	f	f	f	t	f	f	Ergonomic office table with premium finish	Ergonomic office chair with adjustable lumbar support and armrests	\N	LED rope lighting for ambient illumination and modern aesthetics	Modular storage unit with shelves and drawers	\N	Free design consultation and professional installation included for a complete hassle-free workspace transformation	15000.00	10000.00	0.00	50.00	5000.00	0.00	percentage	5.00	41150.00	39092.50	[{"icon": "img/icons/icon_dark_green_panel_20260506_171717_dark_green_panel.png", "name": "Dark green panels", "slug": "dark_green_panel", "price": 350.0, "height": "", "length": "", "breadth": "", "details": "60Cm X 40Cm X 3Cm each panel size for wall decor", "quantity": 35, "has_height": false, "has_length": false, "has_breadth": false}, {"icon": "img/icons/icon_pvc_wood_panel_20260505_171528_pvc_panel.png", "name": "PVC Panel", "slug": "pvc_wood_panel", "price": 1500.0, "height": "", "length": "", "breadth": "", "details": "PVC Wood Panel for Wall Decors", "quantity": 2, "has_height": false, "has_length": false, "has_breadth": false}]	[{"url": "img/leads/media/design_14_2_20260506_195832_nightview.png", "size": 2074071, "type": "image", "order": 1, "filename": "nightview.png"}, {"url": "img/leads/media/design_14_2_20260506_204630_sai_manikonda.mp4", "size": 7081946, "type": "video", "order": 2, "filename": "sai manikonda.mp4"}, {"url": "img/leads/media/design_14_3_20260506_214952_daytime.png", "size": 2468398, "type": "image", "order": 3, "filename": "daytime.png"}]	1	1	1	50	1	1	t	2	1500.00	Premium indoor plants like Monstera, Fiddle Leaf Fig for natural ambiance	t	20	300.00	Mixed sizes Compact desk plants like Succulents, Cacti for workspace decoration	t	4	500.00	Wooden photo/art frames for wall decoration	t	8	700.00	Wooden floating shelves for storage and display	f	1	800.00	Large desk pad/mat	f	1	300.00	Desktop/floor waste bin	f	1	0.00	\N	f	1	0.00	\N	f	1	0.00	\N	f	1	5000.00	Wall painting	f	1	1000.00	Sliding door wardrobe with organized storage and mirror	f	1	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	1	800.00	LED desk lamp with adjustable brightness and color temperature	f	1	300.00	Wooden pen holder for organized desk storage	f	1	1200.00	Vertical laptop stand for space-saving desk organization	with_headrest	t	15	400.00	Aluminum profile lights for wall racks and shelves with elegant finish	4.0	2.0	29.0	3.0	1.5	6.0	50.0	15.0	1x1	3.0	t	1	800.00	Premium multi-socket power strip with surge protection and USB ports	3.0	0.5	6.00	2.00	7.00		
8	6	White Wash	img/leads/media/media_20260503_172119_0_white_wash.png	2	2026-05-03 17:21:19.113537	31540.00	t	t	f	t	f	f	1. 5x2.25ft 29' Inches with Iron Legs(Black)\r\n2. 5ft Wooden Rack	Ergonomic Office Chair		6ft Rope Light for Table Background			Free End-to-End Setup & Installation Services	15000.00	10000.00	0.00	800.00	7000.00	600.00	percentage	5.00	33200.00	31540.00	[]	[{"url": "img/leads/media/media_20260503_172119_0_white_wash.png", "type": "image", "order": 0}, {"url": "img/leads/media/design_8_2_20260503_183028_day-night-white-wash.jpeg", "size": 797132, "type": "image", "order": 2, "filename": "day-night-white-wash.jpeg"}, {"url": "img/leads/media/design_8_3_20260503_183311_day-nightwhitewash.mp4", "size": 3478195, "type": "video", "order": 3, "filename": "day-nightwhitewash.mp4"}]	1	1	1	1	1	1	t	2	1500.00	Standing Plants with Plant Pots	t	4	300.00	Decor Mini Plants 	t	2	600.00	Wall Art Frames	t	2	500.00	2ft Wooden Racks	f	1	1200.00		f	1	500.00		f	1	500.00		f	1	1000.00		f	1	500.00		f	1	5000.00		f	1	1000.00		f	1	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	with_headrest	t	2	500.00	2ft x2 Profile Lighting for Wall Mounted Racks	4.0	2.0	29.0	3.0	1.5	6.0	10.0	10.0	2x3	4.0	f	1	0.00	\N	3.0	1.0	6.00	2.00	7.00	\N	\N
6	6	Wood Rack	img/leads/media/media_20260503_135832_0_wood_rack.png	1	2026-05-03 13:58:32.44225	31540.00	t	t	f	t	f	f	1. 5x2.25ft 29' Inches with Iron Legs(Black)\r\n2. 5ft Wooden Rack	Ergonomic Office Chair		6ft Rope Light for Table Background			Free End-to-End Setup & Installation Services	15000.00	10000.00	0.00	800.00	7000.00	600.00	percentage	5.00	33200.00	31540.00	[]	[{"url": "img/leads/media/design_6_1_20260503_173937_Generate_pictures_night_day_202605032309_1.jpeg", "size": 718359, "type": "image", "order": 1, "filename": "Generate_pictures_night_day_202605032309 (1).jpeg"}, {"url": "img/leads/media/design_6_3_20260503_182317_day-night.mp4", "size": 2857125, "type": "video", "order": 2, "filename": "day-night.mp4"}]	1	1	1	1	1	1	t	2	1500.00	Standing Plants with Plant Pots	t	4	300.00	Decor Mini Plants 	t	2	600.00	Wall Art Frames	t	2	500.00	2ft Wooden Racks	f	1	1200.00		f	1	500.00		f	1	500.00		f	1	1000.00		f	1	500.00		f	1	5000.00		f	1	1000.00		f	1	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	with_headrest	t	2	500.00	2ft x2 Profile Lighting for Wall Mounted Racks	4.0	2.0	29.0	3.0	1.5	6.0	10.0	10.0	2x3	4.0	f	1	0.00	\N	3.0	1.0	6.00	2.00	7.00	\N	\N
10	7	Dark Warm Ambient with Paint	img/leads/media/media_20260504_150947_0_dark_warm_ambient_2.jpeg	2	2026-05-04 15:09:47.298183	46930.00	t	t	f	t	f	f	4x2ft wooden table with black legs x1	Comfortable Ergonomic Chair x1		Rope Lighting behind table	Modular storage unit with shelves and drawers		Free design consultation and professional installation included for a complete hassle-free workspace transformation	2000.00	10000.00	0.00	250.00	5000.00	2000.00	percentage	5.00	49400.00	46930.00	[{"icon": "img/icons/icon_desk_mat_20260503_170116_Screenshot_2026-05-03_at_10.31.05_PM.png", "name": "Desk Mat", "price": 1000.0, "details": "Deskmat", "quantity": 1}]	[{"url": "img/leads/media/media_20260504_150947_0_dark_warm_ambient_2.jpeg", "type": "image", "order": 1}, {"url": "img/leads/media/design_10_2_20260504_152140_dark_warm_ambient_1.jpeg", "size": 817383, "type": "image", "order": 2, "filename": "dark_warm_ambient_1.jpeg"}]	1	1	1	4	1	1	t	2	800.00	Standing Plants for floor x2	t	6	300.00	Decor plants  x6	t	10	500.00	Multi Size Wall frames x10	t	2	1000.00	Wall Mounted Wooden Racks 	t	1	1000.00	Deskmat for keyboard and mouse	f	1	300.00		f	1	1000.00		f	1	2000.00		f	1	800.00		t	1	5000.00	Grey Coloured Wall Painting	f	1	1000.00	Sliding door wardrobe with organized storage and mirror	f	1	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	t	1	1500.00		t	1	500.00	Pen Holder	f	1	1200.00		without_headrest	t	6	500.00	Profile Lighting for 2 Wall Mounted Wooden Racks	4.0	2.0	29.0	3.0	1.5	6.0	4.0	6.0	1x1	4.0	t	1	1000.00	Premium multi-socket power strip with surge protection and USB ports	3.0	1.0	6.00	2.00	7.00	\N	\N
9	7	Warm Magic	img/leads/media/media_20260504_150048_0_warm_Magic.jpeg	1	2026-05-04 15:00:48.19212	40280.00	t	t	f	t	f	f	4x2ft wooden table with black legs	Comfortable Ergonomic Chair		Rope Lighting for 2 Wall Mounted Wooden Racks	Modular storage unit with shelves and drawers		Free design consultation and professional installation included for a complete hassle-free workspace transformation	1800.00	10000.00	0.00	200.00	5000.00	2000.00	percentage	5.00	42400.00	40280.00	[{"icon": "img/icons/icon_desk_mat_20260503_170116_Screenshot_2026-05-03_at_10.31.05_PM.png", "name": "Desk Mat", "price": 1000.0, "details": "mat", "quantity": 1}]	[{"url": "img/leads/media/media_20260504_150048_0_warm_Magic.jpeg", "type": "image", "order": 0}]	1	1	1	4	1	1	t	3	1000.00	Standing Plants for floor 	t	6	300.00	Decor plants	t	10	400.00	Multi Size Wall frames	t	2	1000.00	Wall Mounted Wooden Racks	f	1	800.00		f	1	300.00		f	1	1000.00		f	1	2000.00		f	1	800.00		f	1	5000.00	Grey Coloured Wall Paint	f	1	1000.00	Sliding door wardrobe with organized storage and mirror	f	1	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	t	1	1500.00	Table Lamp for night vision	t	1	500.00	Pen Holder	f	1	1200.00		without_headrest	t	6	400.00	Profile Lighting for Wall Mounted Wooden Racks	4.0	2.0	29.0	3.0	1.5	6.0	4.0	6.0	1x1.25	6.0	t	1	1000.00	Premium multi-socket power strip with surge protection and USB ports	3.0	1.0	6.00	2.00	7.00	\N	\N
11	8	Wooden White	img/leads/media/media_20260505_170540_0_Wooden_White.png	1	2026-05-05 17:05:40.640416	32870.00	t	t	f	f	f	f	Ergonomic office table with premium finish	Ergonomic office chair with adjustable lumbar support and armrests	\N	LED rope lighting for ambient illumination and modern aesthetics	Modular storage unit with shelves and drawers	\N	Free design consultation and professional installation included for a complete hassle-free workspace transformation	1500.00	10000.00	0.00	300.00	5000.00	0.00	percentage	5.00	34600.00	32870.00	[]	[{"url": "img/leads/media/media_20260505_170540_0_Wooden_White.png", "type": "image", "order": 0}]	1	1	1	1	1	1	t	2	1000.00	Premium indoor plants like Monstera, Fiddle Leaf Fig for natural ambiance	t	6	300.00	Compact desk plants like Succulents, Cacti for workspace decoration	f	1	800.00	Wooden photo/art frames for wall decoration	t	2	2000.00	Wooden floating shelves for storage and display	f	1	0.00	\N	f	1	300.00		f	1	0.00	\N	f	1	0.00	\N	f	1	0.00	\N	f	1	5000.00		f	1	1000.00	Sliding door wardrobe with organized storage and mirror	f	1	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	1	800.00		t	1	300.00	Pen Holder	f	1	1200.00		with_headrest	t	8	500.00	Aluminum profile lights for wall racks and shelves with elegant finish	4.0	2.0	29.0	3.0	1.5	6.0	10.0	8.0	2x3	8.0	t	1	500.00	Premium multi-socket power strip with surge protection and USB ports	3.0	1.0	6.00	2.00	7.00	\N	\N
12	8	Warm Ashes	img/leads/media/media_20260505_171006_0_warm_ashes1_.png	2	2026-05-05 17:10:06.545986	46550.00	t	t	f	f	t	f	Ergonomic office table with premium finish	Ergonomic office chair with adjustable lumbar support and armrests	\N	LED rope lighting for ambient illumination and modern aesthetics	Modular storage unit with shelves and drawers	\N	Free design consultation and professional installation included for a complete hassle-free workspace transformation	1500.00	10000.00	0.00	300.00	5000.00	0.00	percentage	5.00	49000.00	46550.00	[{"icon": "img/icons/icon_pvc_wood_panel_20260505_171528_pvc_panel.png", "name": "PVC Panel", "price": 3000.0, "details": "1x8ft PVC Wooden Panel", "quantity": 1}, {"icon": "📝", "name": "Pegboard", "price": 5000.0, "details": "Pegboard to hold the accessories ", "quantity": 1}]	[{"url": "img/leads/media/media_20260505_171006_0_warm_ashes1_.png", "type": "image", "order": 0}, {"url": "img/leads/media/media_20260505_171006_1_warm_ashes2.png", "type": "image", "order": 1}]	1	1	1	1	1	1	t	1	1000.00	Premium indoor plants like Monstera, Fiddle Leaf Fig for natural ambiance	t	6	300.00	Compact desk plants like Succulents, Cacti for workspace decoration	t	2	800.00	Wooden photo/art frames for wall decoration	t	1	2000.00	Wooden floating shelves for storage and display	f	1	0.00	\N	f	1	300.00		f	1	0.00	\N	f	1	0.00	\N	f	1	0.00	\N	f	1	5000.00		f	1	1000.00	Sliding door wardrobe with organized storage and mirror	f	1	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	f	0	0.00	\N	t	1	800.00	LED Desk Lamp	t	1	300.00	Pen Holder	f	1	1200.00		with_headrest	t	12	500.00	Aluminum profile lights for wall racks and shelves with elegant finish	4.0	2.0	29.0	1.5	1.5	2.0	10.0	12.0	2x3	8.0	t	1	500.00	Premium multi-socket power strip with surge protection and USB ports	3.0	1.0	6.00	2.00	7.00	\N	\N
\.


--
-- Data for Name: leads; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.leads (id, customer_name, customer_email, customer_phone, project_name, reference_image, status, discount_type, discount_value, notes, share_token, created_by, created_at, updated_at, location, customer_rating, customer_feedback, feedback_submitted_at, valid_until, is_expired) FROM stdin;
8	Marepalli Sastry		9490107455		img/leads/reference/ref_20260505_170505_Marepalli_Sastry.jpeg	draft	none	0.00	Transform the Current setup to Dream Setup	cSxsP4K0OVT9_0U87XWmRA	14	2026-05-05 17:05:05.226552	2026-05-07 19:03:25.803955	Vizag	\N	\N	\N	2026-05-14 19:03:25.803955	f
6	SK Baji		9949415422	AMM Music Studio	img/leads/reference/ref_20260503_135754_baji.jpg	draft	none	0.00	Transform current workspace into a modern dream setup	wTrLHj1tfN4-5KlW7wOzYA	14	2026-05-03 13:57:54.388253	2026-05-07 19:24:18.854039	Manikonda	5	very good	2026-05-07 18:48:47.734127	2026-05-14 19:24:18.854039	f
9	Sai		6304109306	Trading	img/leads/reference/ref_20260506_192429_sai_trader.jpeg	draft	none	0.00	Transform the Current Setup to Greenery Studio	IEZKEVnWUEOWSdtdZqLXAw	14	2026-05-06 17:24:26.02397	2026-05-08 14:23:07.487236	Manikonda	\N	\N	\N	2026-05-15 14:23:07.487236	f
7	Kalyan		8499856201	Photography	img/leads/reference/ref_20260504_145922_studio_room_4.5x7.5ft.jpeg	draft	none	0.00	Transform a compact 4.5x7.5ft room into a cozy modern workspace with warm lighting, aesthetic wall decor, smart storage, and premium minimalist vibes.	Ms0jiVaHB-8b-muRFOe4TQ	14	2026-05-04 14:59:22.34103	2026-05-09 08:26:14.776918	Khammam	5	chala bagunay designs bt need sometime to decide	2026-05-09 08:26:14.776918	2026-05-16 08:10:12.062064	f
10	kvr eng		9391057113	studio setup	\N	draft	none	0.00	Transform the setup into a dream workspace setup.	HdY2xnbmNG6AWEQq01VuIA	14	2026-05-09 20:18:05.639399	2026-05-09 20:18:05.639399	dilshuknagar	\N	\N	\N	\N	f
11	Lakshmi chowdary		9003239858		\N	draft	none	0.00	no conversion happened sp call back again	7A1QMJSv8NkEG7a_v8TSOA	14	2026-05-09 20:22:40.804511	2026-05-09 20:22:40.804511		\N	\N	\N	\N	f
12	cloud it		9951597143		\N	draft	none	0.00	no conversion happened call back	Vngj_qoSi8_W2tWV80xsqw	14	2026-05-09 20:24:45.957159	2026-05-09 20:24:45.957159		\N	\N	\N	\N	f
13	srinivas goud		8008888834	studio setup	\N	draft	none	0.00	Discussed but no previous exp so he ignored me	lcvXHBQ5XS3zIHh4TsIEgA	14	2026-05-09 20:26:19.563507	2026-05-09 20:26:19.563507		\N	\N	\N	\N	f
14	jeevan kumar		9441113311		\N	draft	none	0.00	may be studio setup bt ignored. call back	LkkG_B11r_9NaqrcscaH3w	14	2026-05-09 20:27:39.679047	2026-05-09 20:27:39.679047		\N	\N	\N	\N	f
15	Ganesh		9441659498		\N	draft	none	0.00	may be need worksetup bt ignored	ngHJrNDDiSAUe1sewBiihg	14	2026-05-09 20:28:41.763083	2026-05-09 20:28:41.763083		\N	\N	\N	\N	f
16	AK		9666904902		\N	draft	none	0.00	no conversion call back	gwVzb00OHI2Y6AqSRqWtuw	14	2026-05-09 20:29:51.250866	2026-05-09 20:29:51.250866		\N	\N	\N	\N	f
17	pandu cheripally		9030751733		\N	draft	none	0.00	Called me for his friend studio setup	njLVy32f4np-15OiXN-jDA	14	2026-05-09 20:31:25.562278	2026-05-09 20:31:25.562278		\N	\N	\N	\N	f
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
49	58	31	1	1.00	Warm Wood	img/Products/31/31.jpg	0	0	/product/31
50	59	30	1	1.00	Semi Wood (Get What You See)	img/Products/30/30.jpg	0	0	/product/30
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.orders (id, user_id, order_date, total_amount, status, user_email, razorpay_order_id, razorpay_payment_id, coupon_code, discount_amount, deal_discount, coupon_discount, status_code, status_updated_at, shipping_name, shipping_phone, shipping_address_line_1, shipping_address_line_2, shipping_city, shipping_state, shipping_pincode, shipping_country, delivery_instructions, company_name, gstin, wallet_amount_used, final_paid_amount, cashback_earned, cashback_credited) FROM stdin;
59	14	2026-05-09 18:10:05.014171	1.00	Packed	srichityala501@gmail.com	order_SnML453zd4YWmC	pay_SnMLYz5OPIrZGC	\N	0.00	0	0	packed	2026-05-09 18:32:34.480533	chityala srikanth	7075077384	Hyderabad		Hyderabad	Telangana	500051	India				0.00	\N	0.00	f
41	14	2025-09-21 07:45:21.288893	1.18	Completed	srichityala501@gmail.com	order_RKApjUNjEhP6S0	pay_RKAq02mcEsKuti	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
43	14	2025-09-21 12:44:58.897377	1.18	Completed	srichityala501@gmail.com	order_RKFwEUlQ1yAlWi	pay_RKFwVFhPR6qVfN	\N	0.00	0.00	0.00	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
49	14	2025-10-12 18:19:06.555201	1.18	Completed	srichityala501@gmail.com	order_RSeqiQvsHN5uJd	pay_RSeqzdSQHqfJSX	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
50	14	2025-10-12 18:30:37.234285	1.18	Completed	srichityala501@gmail.com	order_RSf2rYm4k5RkKo	pay_RSf39bi7eJBSK2	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
51	14	2025-10-12 18:32:01.761722	1.42	Completed	srichityala501@gmail.com	order_RSf4QOuwurvfRF	pay_RSf4e10ZAg5EXr	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
20	14	2025-09-13 19:26:10.335474	1.00	Completed	srichityala501@gmail.com	order_RHCV3q1MNxZRKZ	pay_RHCVLU241SrqF3	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
58	14	2026-04-30 07:12:13.560198	1.00	Confirmed	srichityala501@gmail.com	order_SjcJtkv5uYZQDG	pay_SjcKYTtl2ceLW7	\N	0.00	0	0	confirmed	2026-04-30 07:12:13.560193	chityala srikanth	7075077384	Hyderabad		Hyderabad	Telangana	500051	India				0.00	\N	0.00	f
54	14	2026-04-11 04:21:05.979416	1.18	Confirmed	srichityala501@gmail.com	order_Sc3GDd4Ow8k9t1	pay_Sc3GWgrF73RTqh	\N	0.00	0	0	confirmed	2026-04-11 04:21:05.979413	chityala srikanth	7075077384	Hyderabad		Hyderabad	Telangana	500051	India				0.00	\N	0.00	f
5	14	2025-08-23 20:16:01.177902	1.00	Completed	srichityala501@gmail.com	order_R8u83hCdEGGxiW	pay_R8u8ThGoiLNCSQ	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
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
23	14	2025-09-13 20:02:18.112725	1.00	Completed	srichityala501@gmail.com	order_RHD7K9BmbuO9cP	pay_RHD7USgozHDpT6	\N	0.00	0	0	completed	2026-04-11 04:19:00.585512								India				0.00	\N	0.00	f
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
\.


--
-- Data for Name: otp_verifications; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.otp_verifications (id, email, otp_code, name, password, attempts, created_at, expires_at, verified) FROM stdin;
4	srisaisagar789@gmail.com	332634	sai	998969	0	2026-04-18 15:26:37.320739	2026-04-18 15:31:37.320697	t
5	sri.chityala500@gmail.com	426424	sreekanth	998969	0	2026-04-23 14:09:04.493304	2026-04-23 14:14:04.493257	t
\.


--
-- Data for Name: page_views; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.page_views (id, visitor_id, page_url, page_title, referrer, time_spent, session_id, ip_address, user_agent, created_at) FROM stdin;
1	2af1970f-349f-4b03-af34-8f4a14c2f56e	/login	login	Direct	0	812cb861-1945-4432-8ba2-35a6fa82fc61	217.113.194.97	Mozilla/5.0 (compatible; Barkrowler/0.9; +https://babbar.tech/crawler)	2026-05-09 17:44:37.45688
2	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals	admin_deals	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:44:53.85143
3	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals	admin_deals	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:45:06.773667
4	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/visitors	visitor_tracking.admin_visitors	Direct	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:45:26.713376
5	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:45:31.912331
6	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:45:35.97941
7	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/visitors	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:45:37.92424
8	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users	admin_users.manage_users	https://gspaces.in/admin/deals	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:46:17.460049
9	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:46:41.542199
10	5f15e2e8-ac8c-499f-b998-4b07e60ce77a	/	index	Direct	0	6fcc752d-1fad-498c-a2d1-ae6e9f8d3a46	204.76.203.206	Mozilla/5.0	2026-05-09 17:46:44.536398
11	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users	admin_users.manage_users	https://gspaces.in/admin/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:46:46.293278
12	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:46:50.574749
13	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:47:22.771747
14	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:47:25.151543
15	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:48:25.421364
16	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:48:27.840597
17	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:48:29.048408
18	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:48:30.125499
19	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:48:31.214982
20	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:48:40.60516
21	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:48:41.112428
22	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:48:58.544082
23	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/referral-coupons	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:49:02.332284
24	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/coupons	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:49:04.075656
601	3980b12b-7cfb-431e-bc72-935680390502	/dropdown.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:36.636807
25	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/referral-coupons	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:49:17.812218
26	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/coupons	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:49:21.054003
27	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/referral-coupons	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:49:29.921481
28	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/referral-coupons	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:49:58.373845
29	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/coupons	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:50:03.454888
30	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:50:06.390839
31	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:50:14.291146
32	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=1&device=all&country=all	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:50:18.013903
33	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=30&device=all&country=all	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:50:21.352164
34	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=1&device=all&country=all	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:50:51.859812
35	03537714-734f-4b72-aaf0-42bda7ae02b8	/	index	Direct	0	7df7c787-8aa5-45d4-ace5-60c125dcf335	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 17:51:08.961182
36	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=1&device=all&country=all	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:51:11.345857
37	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=1&device=all&country=all	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:51:40.766464
38	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=30&device=all&country=all	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:51:47.527933
39	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/visitors?date_filter=30&device=Mobile&country=all	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:51:52.093555
40	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:52:52.496647
41	d4c0e192-544f-4116-9e2c-6ae82c21809a	/	index	Direct	0	bd0cd6ae-8307-4744-95f4-46002415bdbe	204.76.203.206	Mozilla/5.0	2026-05-09 17:53:29.188888
42	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:53:52.942722
43	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:54:53.370262
44	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:55:40.62317
45	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/inquiries	admin_inquiries	https://gspaces.in/admin/leads	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:55:46.040599
46	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/inquiries	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:57:34.087809
73	e75a1160-ecdc-4847-bf6c-484ce313cb8a	/blogs	blogs	Direct	0	82f08890-8afa-4f98-b411-d812e9b51048	127.0.0.1	python-requests/2.25.1	2026-05-09 18:02:15.005069
47	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:57:44.48025
48	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:57:53.902939
49	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:57:57.963879
50	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:58:03.2109
51	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=1&device=all&country=all	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:58:33.616311
52	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/admin/visitors?date_filter=1&device=all&country=all	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:58:39.963578
53	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:58:43.701581
54	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:58:46.999306
55	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:58:52.78262
56	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/corporate	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 17:58:59.884162
57	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:01:50.960288
58	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/orders	admin_orders	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:01:51.743099
59	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/orders	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:01:55.404217
60	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:01:55.651404
61	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:01:55.748567
62	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals	admin_deals	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:01:55.751559
63	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/reviews	admin_reviews	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:02:05.59752
64	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/reviews	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:02:07.786807
65	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users	admin_users.manage_users	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:02:08.006615
66	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:02:08.008175
67	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:02:13.660919
68	b9101bf5-033e-4db7-91ba-4e9d451a1d53	/	index	Direct	0	4506a5af-ad93-444b-b023-a22455ee78bd	127.0.0.1	python-requests/2.25.1	2026-05-09 18:02:14.765841
69	ea428b9f-e861-443b-801f-59d60585ef13	/products	products	Direct	0	5b22ce24-8349-4170-ae14-6dfb402a5636	127.0.0.1	python-requests/2.25.1	2026-05-09 18:02:14.818008
70	56f4ad25-4b33-454c-b63c-341c0cd0d472	/about	about	Direct	0	2760040e-adb7-4811-a10c-0169ed766a1e	127.0.0.1	python-requests/2.25.1	2026-05-09 18:02:14.890641
71	ec62ef17-b874-49c8-b46d-3b9bcab2323d	/contact	contact	Direct	0	a0104ad3-b03d-48bf-ab21-80d3baa41907	127.0.0.1	python-requests/2.25.1	2026-05-09 18:02:14.931095
72	3478d5c3-dba5-4c4b-95c9-006a6819e956	/services	services	Direct	0	4ef2a0ab-436c-49a0-9d86-caf7aa3197be	127.0.0.1	python-requests/2.25.1	2026-05-09 18:02:14.969083
74	dc03f34f-99d2-4bf1-ae8f-da9c1e0a1c7f	/login	login	Direct	0	4418eb6a-2b54-42e0-9978-b15cd448913c	127.0.0.1	python-requests/2.25.1	2026-05-09 18:02:15.06396
75	7507e50b-f1fc-4c39-a78e-a166aebd1024	/signup	signup	Direct	0	28d39adb-5f69-406b-9593-6c61826f6a66	127.0.0.1	python-requests/2.25.1	2026-05-09 18:02:15.097751
76	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:02:50.044137
77	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:02:53.285184
78	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/default-prices	leads.manage_default_prices	https://gspaces.in/admin/visitors?date_filter=1&device=all&country=all	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:03:16.052626
79	b1db4c05-4cae-4f68-84a6-d740e8bd2207	/	index	Direct	0	4adea99c-cb24-4470-b5be-61aab8fb2b80	60.253.237.224	Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp¡±)	2026-05-09 18:03:17.932814
80	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/default-prices	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:03:18.176355
81	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:03:18.408218
82	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals	admin_deals	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:03:18.500249
83	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:03:18.508094
84	4b5e0166-41ed-4989-a23f-68720126cdf5	/	index	Direct	0	f91cb6bc-e8e4-40e3-8d72-64919317ac9a	204.76.203.206	Mozilla/5.0	2026-05-09 18:03:51.994949
85	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/orders	admin_orders	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:08:44.280022
86	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/products	products	https://gspaces.in/admin/orders	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:08:45.187636
87	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/edit_product/30	edit_product	https://gspaces.in/products	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:08:49.109889
88	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/edit_product/30	edit_product	https://gspaces.in/edit_product/30	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:08:52.617253
89	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/edit_product/30	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:08:52.811515
90	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/products	products	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:08:56.651006
91	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/add_to_cart/30	add_to_cart	https://gspaces.in/products	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:08:59.471456
92	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/cart	cart	https://gspaces.in/products	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:08:59.666339
93	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/update_quantity/30/decrease	update_quantity	https://gspaces.in/cart	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:09:20.177142
94	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/cart	cart	https://gspaces.in/cart	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:09:20.427261
95	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/payment/success	payment_success	https://gspaces.in/cart	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:10:04.959624
96	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/thankyou	thankyou	https://gspaces.in/cart	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:10:11.292858
97	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/profile	profile	https://gspaces.in/thankyou?order_id=59	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:10:17.445099
98	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/orders	admin_orders	https://gspaces.in/profile	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:10:40.68108
174	6ae05d64-16b7-4583-aca1-6ddad8b5c5ce	/	index	Direct	0	525db091-0b19-4a98-bfa6-7ab0c2995778	185.191.171.19	Mozilla/5.0 (compatible; SemrushBot/7~bl; +http://www.semrush.com/bot.html)	2026-05-09 18:26:06.168649
99	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/orders	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:10:42.284277
100	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:10:45.196679
101	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/referral-coupons	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:10:53.762747
102	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals	admin_deals	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:10:55.300287
103	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/deals	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:11:05.877229
104	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:11:09.733562
105	3e57a3a3-3c86-4f04-ae9b-085f61ed769b	/	index	Direct	0	e484b232-a6d5-4337-a312-2c97dfcb75b4	204.76.203.206	Mozilla/5.0	2026-05-09 18:11:10.400668
106	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users	admin_users.manage_users	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:11:11.29894
107	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/users	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:11:16.924592
108	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/users	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:13:20.341585
109	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:13:20.604478
110	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:13:24.256598
111	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:13:24.5084
112	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:13:27.029724
113	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals	admin_deals	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:13:31.620894
114	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:13:33.873176
115	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:13:36.181011
116	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:13:36.406288
117	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:13:46.67388
118	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:13:46.909959
119	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/default-prices	leads.manage_default_prices	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:14:10.079689
120	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/default-prices	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:14:11.893998
121	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/leads	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:14:13.852318
602	3980b12b-7cfb-431e-bc72-935680390502	/ahutr.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:36.810879
122	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:14:14.091242
123	2f54c7dd-ac8a-4afa-b82e-050cbad6ad41	/.env	Unknown	Direct	0	faa09ec6-4998-4f9e-abd8-6d02cfb8a130	203.159.90.86	Go-http-client/1.1	2026-05-09 18:16:19.667625
124	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/leads	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:19:18.671833
125	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:19:18.92415
126	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users	admin_users.manage_users	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:19:22.877617
127	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/orders	admin_orders	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:19:51.557452
128	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/inquiries	admin_inquiries	https://gspaces.in/admin/orders	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:19:52.495548
129	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/inquiries	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:19:53.302655
130	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/default-prices	leads.manage_default_prices	https://gspaces.in/admin/leads	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:19:54.173885
131	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/default-prices	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:19:54.91781
132	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:19:55.155757
133	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/reviews	admin_reviews	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:19:56.659171
134	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/gst-settings	admin_gst_settings	https://gspaces.in/admin/reviews	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:19:58.804194
135	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/gst-settings	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:20:00.364708
136	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:20:00.619195
137	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/orders	admin_orders	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:20:26.210308
138	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/inquiries	admin_inquiries	https://gspaces.in/admin/orders	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:20:27.269212
139	ee6a6801-e06d-4e11-997d-eef5802e2516	/robots.txt	Unknown	Direct	0	a525ea3f-5f5d-41d1-9645-875e2c2fc85a	104.210.140.136	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36; compatible; OAI-SearchBot/1.0; +https://openai.com/searchbot	2026-05-09 18:21:29.185241
140	e58738db-7632-45be-ad25-c730c5e8f2f2	/	index	Direct	0	cb57d38e-82d1-493c-af79-9b088639f173	216.180.246.1	Mozilla/5.0 (compatible; GenomeCrawlerd/1.0; +https://www.nokia.com/genomecrawler)	2026-05-09 18:21:33.117056
141	af5167ad-ceb9-4cf2-9d11-8be679c6fd08	/	index	http://www.gspaces.in/	0	7008d562-0a3c-4ca4-ad34-33d8a6a4a12c	205.210.31.58	Hello from Palo Alto Networks, find out more about our scans in https://docs-cortex.paloaltonetworks.com/r/1/Cortex-Xpanse/Scanning-activity	2026-05-09 18:21:52.144448
142	0c5599bf-0f74-4170-8f88-b4b778321cac	/	index	Direct	0	b2dbbc4a-2558-4304-9ebe-dafa85846728	216.180.246.1	Mozilla/5.0 (compatible; GenomeCrawlerd/1.0; +https://www.nokia.com/genomecrawler)	2026-05-09 18:22:14.933148
143	1c979877-8c9c-4f3b-87f3-a7b72f4b9aa0	/	index	Direct	0	80fb65e4-c0d6-4f7e-9074-c32e6e58f293	204.76.203.206	Mozilla/5.0	2026-05-09 18:23:07.496103
144	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/inquiries	admin_inquiries	https://gspaces.in/admin/orders	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:23:11.489622
145	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/orders	admin_orders	https://gspaces.in/admin/inquiries	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:23:13.178344
146	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/inquiries	admin_inquiries	https://gspaces.in/admin/orders	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:23:14.108351
147	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/inquiries	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:23:14.994116
148	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/default-prices	leads.manage_default_prices	https://gspaces.in/admin/leads	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:23:16.119238
149	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/default-prices	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:23:16.973268
150	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:23:17.217529
151	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:23:20.245238
152	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals	admin_deals	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:23:22.818085
153	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/gst-settings	admin_gst_settings	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:23:25.197829
154	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/gst-settings	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:23:27.206415
155	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:23:27.441311
156	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/gst-settings	admin_gst_settings	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:24:10.974509
157	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/default-prices	leads.manage_default_prices	https://gspaces.in/admin/gst-settings	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:24:12.930885
158	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/default-prices	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:24:14.268194
159	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:24:14.512749
160	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:24:17.744811
161	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:24:58.827202
162	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:25:02.118237
163	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/visitors?date_filter=1&device=all&country=all	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:25:09.532292
164	42deb8aa-71c0-431e-b424-376502e312dc	/robots.txt	Unknown	Direct	0	bfa8bd8b-feab-4f03-b2d7-589f9855ab74	45.167.232.164	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.6422.141 Safari/537.36	2026-05-09 18:25:10.90771
165	3c6baaf9-e24f-4a0f-a5ef-58ce2289a866	/	index	Direct	0	2eb68029-f97a-4f5e-b82c-61628fb45363	127.0.0.1	python-requests/2.25.1	2026-05-09 18:25:12.614613
166	b744aa92-8d9d-46a0-a535-6e574dcc6225	/products	products	Direct	0	130a8401-c696-44c7-b88f-01f665e61340	127.0.0.1	python-requests/2.25.1	2026-05-09 18:25:12.686664
167	5cb8fd81-58a1-4ae8-945d-be145c5d0baf	/about	about	Direct	0	c3951e14-5d6d-457b-9f12-06f7c325335e	127.0.0.1	python-requests/2.25.1	2026-05-09 18:25:12.749488
168	e83a54dc-5d22-4360-afe4-617b1a727cd1	/contact	contact	Direct	0	ee7a5f03-064e-4203-b9cd-1c241991e810	127.0.0.1	python-requests/2.25.1	2026-05-09 18:25:12.791025
169	4f379cba-a7d2-4a30-a2a6-644676d6b0f0	/services	services	Direct	0	8a558532-62e1-473a-a26a-0c78a7d9aade	127.0.0.1	python-requests/2.25.1	2026-05-09 18:25:12.82967
170	4fac2386-7f4d-48d3-be62-d1c5ef21aa47	/blogs	blogs	Direct	0	e9177313-87bd-42ff-9aeb-d4f263c161dd	127.0.0.1	python-requests/2.25.1	2026-05-09 18:25:12.866168
171	1ae9bc7d-41b5-4c85-98b4-8b465d8b0891	/login	login	Direct	0	60d08c45-0b53-4204-b539-b2b53a69c3df	127.0.0.1	python-requests/2.25.1	2026-05-09 18:25:12.923445
172	cd469895-ee62-43f4-9dcc-7594fc9b8709	/signup	signup	Direct	0	b665b522-1b94-406c-824a-7d8c657feaf5	127.0.0.1	python-requests/2.25.1	2026-05-09 18:25:12.961067
173	efe43d82-109e-4435-9c9d-b6401c0a638d	/robots.txt	Unknown	Direct	0	0122d9d3-402e-46fa-9043-f04f2fa6962b	185.191.171.3	Mozilla/5.0 (compatible; SemrushBot/7~bl; +http://www.semrush.com/bot.html)	2026-05-09 18:26:05.118457
175	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:26:09.98095
176	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/system-health	visitor_tracking.admin_system_health	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:26:23.022388
177	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/system-health	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:26:24.862676
178	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/visitors	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:26:34.391654
179	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:26:34.648852
180	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:26:39.654859
181	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals	admin_deals	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:26:41.519958
182	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:26:43.938575
183	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:28:11.596727
184	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:28:11.815755
185	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users	admin_users.manage_users	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:28:14.041597
186	06d3dcef-9c97-4f06-b590-a053b7a95c6b	/	index	Direct	0	0536d6a5-b689-471e-9e22-a8ba62c5f754	204.76.203.206	Mozilla/5.0	2026-05-09 18:29:49.812618
187	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/orders	admin_orders	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:05.725915
188	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/inquiries	admin_inquiries	https://gspaces.in/admin/orders	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:06.886478
189	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/inquiries	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:08.050355
190	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/default-prices	leads.manage_default_prices	https://gspaces.in/admin/leads	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:09.353783
191	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/default-prices	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:10.250803
192	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:10.492593
193	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:13.43382
194	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals	admin_deals	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:14.288088
195	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:15.581598
196	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:20.12507
197	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:20.371178
603	3980b12b-7cfb-431e-bc72-935680390502	/hypo.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:37.001258
198	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users	admin_users.manage_users	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:23.349538
199	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:27.954058
200	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:28.203493
201	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons/delete/3	delete_coupon	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:37.665686
202	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons/delete/3	Unknown	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:30:51.0769
203	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:31:18.929497
204	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:31:19.204255
205	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:31:21.630679
206	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:31:35.546038
207	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals	admin_deals	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:31:50.969527
208	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:31:55.383107
209	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:31:55.639706
210	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users	admin_users.manage_users	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:31:56.679483
211	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/orders	admin_orders	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:32:27.712826
212	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/orders/update_status/59	update_order_status	https://gspaces.in/admin/orders	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:32:34.453253
213	935c8ab2-1a0f-4e6f-9039-e10b98e7ed0c	/	index	Direct	0	1c03d647-6385-4403-8a45-6cf185536c49	216.180.246.1	Mozilla/5.0 (compatible; GenomeCrawlerd/1.0; +https://www.nokia.com/genomecrawler)	2026-05-09 18:32:34.692106
214	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/orders	admin_orders	https://gspaces.in/admin/orders	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:32:41.403211
215	b7f0cf6c-92b0-4895-9589-b658942030c2	/robots.txt	Unknown	Direct	0	ff0d3c63-a364-46b7-b58a-dd37841867be	216.73.216.13	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)	2026-05-09 18:33:03.441248
216	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/orders	admin_orders	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:35:34.512292
217	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/inquiries	admin_inquiries	https://gspaces.in/admin/orders	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:35:35.95703
218	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/inquiries	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:35:44.360277
219	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:35:44.591351
220	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:35:45.502235
221	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals	admin_deals	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:35:46.873384
222	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:35:48.076819
223	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:35:48.330256
224	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users	admin_users.manage_users	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:35:49.141456
225	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:35:50.47808
226	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users-management	admin_users_management	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:38:25.217765
227	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/customers	admin_customers	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:38:25.552589
228	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/users	admin_users.manage_users	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:38:28.170425
229	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals-promotions	admin_deals_promotions	https://gspaces.in/admin/users-management	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:38:33.224797
230	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/coupons	admin_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:38:33.482239
231	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:38:35.103026
232	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/deals	admin_deals	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:38:38.918041
233	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/admin/referral-coupons	admin_referral_coupons	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:38:40.019689
234	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/customers	customer_inquiry_page	https://gspaces.in/admin/deals-promotions	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:38:47.271234
235	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:38:53.668747
236	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:39:10.406855
237	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/services	services	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:39:12.323594
238	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/service	Unknown	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:39:15.371799
239	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/services	services	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:39:17.361249
240	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:39:18.004816
241	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	Unknown	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:40:27.948307
242	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:40:30.923306
243	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:40:32.798862
244	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/products	products	https://gspaces.in/corporate	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:40:34.087732
245	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/products	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:40:35.435127
604	3980b12b-7cfb-431e-bc72-935680390502	/.yuf.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:37.173475
246	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/products	products	https://gspaces.in/corporate	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:40:40.858693
247	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/blogs	blogs	https://gspaces.in/products	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:40:42.022029
248	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/customers	customer_inquiry_page	https://gspaces.in/blogs	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:40:43.884273
249	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/products	products	https://gspaces.in/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:40:45.625311
250	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/products	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:40:47.013327
251	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/corporate	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:40:47.772711
252	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:44:15.701531
253	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:44:17.193198
254	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/products	products	https://gspaces.in/corporate	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:44:18.097833
255	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/blogs	blogs	https://gspaces.in/products	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:44:18.98174
256	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/customers	customer_inquiry_page	https://gspaces.in/blogs	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:44:19.707039
257	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/my-workspace	my_workspace	https://gspaces.in/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:44:27.867047
258	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/customers	customer_inquiry_page	https://gspaces.in/blogs	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:44:31.338652
259	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:45:54.508784
260	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/products	products	https://gspaces.in/corporate	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:45:55.56989
261	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/blogs	blogs	https://gspaces.in/products	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:45:56.378029
262	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/customers	customer_inquiry_page	https://gspaces.in/blogs	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:45:57.397724
263	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/quotation/Ms0jiVaHB-8b-muRFOe4TQ	leads.view_quotation	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:46:46.133412
264	c3ad20fd-94ff-47d5-9dfe-6ad77a7f6477	/	index	Direct	0	4476cd2b-2394-4609-91e8-9797360550ef	204.76.203.206	Mozilla/5.0	2026-05-09 18:48:19.213796
265	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/customers	customer_inquiry_page	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:53:06.481352
266	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:53:08.321843
267	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:53:10.120748
268	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:55:46.911805
269	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/customers	customer_inquiry_page	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:56:05.718084
270	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/my-workspace	my_workspace	https://gspaces.in/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:56:08.820715
527	84f3d7ec-bcc2-47c9-9c6d-c67bebe96df1	/	index	Direct	0	3f369418-d6b2-481a-a908-62516dbff792	213.188.78.130	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	2026-05-09 23:19:53.52916
271	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/customers	customer_inquiry_page	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:56:12.795615
272	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:56:19.244733
273	07909004-1680-4a0e-8b66-71ba219b2b14	/backend/app/.git/config	Unknown	Direct	0	61d8a07b-8542-42cc-b26c-6f719f7b3df8	206.189.1.73	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.129 Safari/537.36	2026-05-09 18:56:28.170318
274	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/customers	customer_inquiry_page	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:57:15.828734
275	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:57:48.245016
276	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/products	products	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:57:54.250356
277	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/products	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:57:55.908255
278	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/customers	customer_inquiry_page	https://gspaces.in/corporate	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:57:57.398265
279	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/blogs	blogs	https://gspaces.in/customers	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:57:58.480959
280	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/products	products	https://gspaces.in/blogs	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:58:00.834553
281	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/products	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:58:02.170739
282	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:58:02.973656
283	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 18:58:03.951037
284	afeb4f9e-606e-4ad2-8a13-8520c2526aac	/	index	Direct	0	ffa8f8f0-fa68-45b6-a0fa-41800a0bc106	204.76.203.206	Mozilla/5.0	2026-05-09 18:58:27.365145
285	3ac68b1c-396c-4ec0-bd55-c5665ccfa9fc	/delete_sub_image/130	Unknown	Direct	0	4f7fe543-cbbf-4706-a781-16038197ffe4	85.208.96.212	Mozilla/5.0 (compatible; SemrushBot/7~bl; +http://www.semrush.com/bot.html)	2026-05-09 19:00:59.466174
286	2bc3f34f-03f4-4a94-b3fb-a3c20841c5a5	/services	Unknown	Direct	0	7d88c582-56d8-4fc8-8b72-5e6d59f5c6a4	2a03:2880:f806:47::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-09 19:01:57.571847
287	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	Direct	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:02:26.656813
288	7367faa4-00e2-4d39-a098-d8cd7fb7195c	/	index	Direct	0	3cb5bf8b-e445-4431-9e9e-6e55fb3bea78	3.130.168.2	visionheight.com/scan Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/126.0.0.0 Safari/537.36	2026-05-09 19:05:02.994338
289	32946995-2872-4f2c-8dac-21a055c3fddd	/	index	Direct	0	15842056-ee1a-4d18-b663-f2749bf6e145	3.130.168.2	visionheight.com/scan Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/126.0.0.0 Safari/537.36	2026-05-09 19:05:48.330308
290	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:06:06.250911
291	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:06:15.002515
292	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:06:16.862917
293	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:06:26.904426
294	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/products	products	https://gspaces.in/corporate	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:06:29.416379
295	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/products	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:06:31.159143
296	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:06:39.224022
297	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:07:19.167829
298	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:07:50.159732
299	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:07:51.330585
300	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/my-workspace	my_workspace	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:08:24.799728
301	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/profile	profile	https://gspaces.in/my-workspace	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:08:32.789895
302	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/profile	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:08:37.955756
303	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:08:38.915198
304	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:10:44.008807
305	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/corporate	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:10:48.396428
306	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:10:49.652682
307	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:10:51.799186
308	4975d471-53be-4026-a3e3-89b28f5aa219	/sitemap.xml	serve_sitemap	Direct	0	5dcf982f-0cfe-463d-b35c-c3693319ffaf	51.68.247.194	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-09 19:11:40.254136
309	9c4e4ffb-1ccf-461e-acdb-df36cd3d253e	/.env	Unknown	Direct	0	58aeadf1-7965-4119-a652-24ec4c698f50	216.10.27.45	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	2026-05-09 19:11:54.33039
310	665e0b28-9b99-46d7-9a5d-bfd2ac249985	/	Unknown	Direct	0	681d7e51-c586-4fa3-a6fa-fd798f4e7cfb	216.10.27.45	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	2026-05-09 19:11:55.140257
311	23fed778-0871-4791-86f7-eb0f244b9cb1	/	index	Direct	0	96e66419-b81a-40cf-92c7-0f5c654fcfbe	204.76.203.206	Mozilla/5.0	2026-05-09 19:13:42.990003
312	3058b4a9-ce43-4d81-a369-9b15877a3ec1	/delete_sub_image/131	Unknown	Direct	0	6384ae32-0b61-4955-9a5e-ae4b8bae79eb	85.208.96.194	Mozilla/5.0 (compatible; SemrushBot/7~bl; +http://www.semrush.com/bot.html)	2026-05-09 19:14:01.15077
313	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:14:13.525266
314	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/corporate	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:14:15.13425
315	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/corporate	corporate	https://gspaces.in/about	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:14:15.881043
316	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/	index	https://gspaces.in/corporate	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:14:30.95892
317	730254b5-c888-4bcb-bbce-53ffc2ffff5d	/about	about	https://gspaces.in/	0	b837c228-de5c-4737-b48b-90ce066dc01b	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:14:32.297254
318	03537714-734f-4b72-aaf0-42bda7ae02b8	/	index	Direct	0	7df7c787-8aa5-45d4-ace5-60c125dcf335	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 19:14:44.417115
319	03537714-734f-4b72-aaf0-42bda7ae02b8	/quotation/IEZKEVnWUEOWSdtdZqLXAw	leads.view_quotation	Direct	0	7df7c787-8aa5-45d4-ace5-60c125dcf335	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 19:14:49.52428
320	03537714-734f-4b72-aaf0-42bda7ae02b8	/favicon.ico	Unknown	https://gspaces.in/quotation/IEZKEVnWUEOWSdtdZqLXAw	0	7df7c787-8aa5-45d4-ace5-60c125dcf335	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 19:14:50.599953
321	03537714-734f-4b72-aaf0-42bda7ae02b8	/admin/leads/9/edit	leads.edit_lead	https://gspaces.in/admin/leads/9/edit	0	7df7c787-8aa5-45d4-ace5-60c125dcf335	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 19:14:55.37189
322	03537714-734f-4b72-aaf0-42bda7ae02b8	/login	login	https://gspaces.in/admin/leads/9/edit	0	7df7c787-8aa5-45d4-ace5-60c125dcf335	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 19:14:55.546956
323	60c63a2c-6372-43b8-885f-126d95544f1e	/	index	Direct	0	6b3f0c6f-fea7-4c23-b8be-024e75c15c92	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 19:15:05.709587
605	3980b12b-7cfb-431e-bc72-935680390502	/lef.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:37.35181
324	60c63a2c-6372-43b8-885f-126d95544f1e	/products	products	https://gspaces.in/	0	6b3f0c6f-fea7-4c23-b8be-024e75c15c92	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 19:15:24.08781
325	60c63a2c-6372-43b8-885f-126d95544f1e	/my-workspace	my_workspace	https://gspaces.in/products	0	6b3f0c6f-fea7-4c23-b8be-024e75c15c92	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 19:15:38.780441
326	60c63a2c-6372-43b8-885f-126d95544f1e	/login	login	https://gspaces.in/products	0	6b3f0c6f-fea7-4c23-b8be-024e75c15c92	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 19:15:39.004994
327	60c63a2c-6372-43b8-885f-126d95544f1e	/products	products	https://gspaces.in/	0	6b3f0c6f-fea7-4c23-b8be-024e75c15c92	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 19:15:44.014112
328	60c63a2c-6372-43b8-885f-126d95544f1e	/contact	contact	https://gspaces.in/products	0	6b3f0c6f-fea7-4c23-b8be-024e75c15c92	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 19:15:47.140088
329	60c63a2c-6372-43b8-885f-126d95544f1e	/corporate	corporate	https://gspaces.in/contact	0	6b3f0c6f-fea7-4c23-b8be-024e75c15c92	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-09 19:16:00.541843
330	22275a15-fb71-40f3-a7bb-f6dc25d84a37	/	index	Direct	0	3777e9ae-aacb-46a5-865a-17038dbc22c3	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 19:18:52.370417
331	d91d11f0-2601-43c0-a11d-22ef81ff88a6	/sitemap.xml	serve_sitemap	Direct	0	dc4bc601-6f3b-402d-8c88-803ea975c21c	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	2026-05-09 19:20:53.832392
332	aa8b0498-ba83-4d5d-9029-406aee410c6c	/Core/Skin/Login.aspx	Unknown	Direct	0	6529503e-2e1c-4de0-8130-ec2ced711a68	43.129.169.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36	2026-05-09 19:23:30.945844
333	937daf18-0e92-447e-97da-64420409be96	/	index	Direct	0	ee1e3b3b-4708-40d2-847c-8bb19b769f0f	204.76.203.206	Mozilla/5.0	2026-05-09 19:25:00.316292
334	aea7f32b-57d6-4514-a61d-c3f2b07476ce	/	index	Direct	0	83982821-1dff-4b5c-baf0-52d82f4782b8	112.86.225.39	Sogou web spider/4.0(+http://www.sogou.com/docs/help/webmasters.htm#07)	2026-05-09 19:25:51.213984
335	12eb46ea-ae6e-4e99-a136-aa1457a1f3c6	/	index	Direct	0	be51b336-0729-4241-887c-52b342161b49	204.76.203.206	Mozilla/5.0	2026-05-09 19:30:26.543258
336	7130629e-3b57-4086-bc2e-7d3632ef443a	/product/24	product_detail	Direct	0	2cba6ce1-4df5-4802-a591-70d258f8882a	2a03:2880:f806:6::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-09 19:34:27.830874
337	790d3c4f-f90b-489c-8dea-6f84b955b512	/my-workspace	my_workspace	Direct	0	33fb2c28-6ddb-442a-a1ef-01627a83c563	2a03:2880:f806:1a::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-09 19:34:48.392877
338	3d286c2b-407a-4629-b2af-62561c8092e7	/login	login	Direct	0	cd010a03-e565-4df9-a3ee-7591471d38e2	2a03:2880:f806:15::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-09 19:35:12.027413
339	74158840-f518-484e-8b8e-8853bc40f2e7	/@fs/etc/passwd	Unknown	Direct	0	e63db1ba-b751-4b1c-8020-5da05f2448c7	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:49.304266
340	b4286ff7-5413-467e-b7ce-053561a39a62	/@fs/etc/passwd	Unknown	Direct	0	dc71f145-d419-49cd-937f-d1cb257e5792	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:49.475195
341	c37a9b2e-3e22-4566-9755-19353afa1f12	/@fs/etc/passwd	Unknown	Direct	0	11ee64ca-81d8-4fb3-a40c-8684881f0031	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:49.640732
342	0bcbfb52-0e7b-4991-9536-06395f5f18db	/@fs/etc/passwd	Unknown	Direct	0	acae0412-a70f-4cb6-a0b5-6922a1d19bcf	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:49.809021
343	2838a882-76f5-4484-a856-6c0382267e01	/@fs/etc/shadow	Unknown	Direct	0	374c7f3b-2d7c-4c83-aafe-061ec9e8c797	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:49.974347
344	a0ff33fc-b73a-45f4-8eb5-e67f61cf32ab	/@fs/etc/shadow	Unknown	Direct	0	b1f35f16-f10a-4143-b125-a72de5d60573	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:50.14759
345	6183ce65-450f-48ed-a822-ec11ee15aaec	/@fs/etc/shadow	Unknown	Direct	0	bb8ab1fa-8c50-41aa-bd02-a6d3e2da0a7e	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:50.312603
346	be09c0ed-c088-469b-a210-d3d5de900496	/@fs/etc/shadow	Unknown	Direct	0	e1a8f73d-758f-47d4-97d5-bbbfe6cbd775	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:50.480746
347	f045ecf6-b37f-4bfe-b0fe-dd2de504ab94	/@fs/proc/self/environ	Unknown	Direct	0	69673396-be84-4e52-b906-578a872615c5	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:50.649137
348	0d8e946a-f080-4004-bbd7-72463a9e3ae2	/@fs/proc/self/environ	Unknown	Direct	0	146ad749-6f39-4740-af86-5f10b20a623c	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:50.816201
349	ff37723f-d864-4cc0-8797-67f106c493a0	/@fs/proc/self/environ	Unknown	Direct	0	63ee12da-cc12-4372-a83b-12d99ff555d0	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:50.986973
350	66ae1903-229a-47ca-8d53-61356a49b6ac	/@fs/proc/self/environ	Unknown	Direct	0	36951981-6fc2-49b8-8836-0fda7735271c	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:51.156955
351	b16a9af9-1c57-4aec-994f-1ac0ffbd094b	/@fs/proc/self/cmdline	Unknown	Direct	0	2d55f8f5-cf17-4e20-ab79-488e2be3becb	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:51.325966
352	e0d2d276-bfe9-4bc8-a455-83fccc28337d	/@fs/proc/self/cmdline	Unknown	Direct	0	8007a3f9-3b46-475b-a0f9-45a871a3d42f	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:51.49337
606	3980b12b-7cfb-431e-bc72-935680390502	/snus.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:37.526306
353	e5d9a50a-734d-4d83-8090-59a9679312ea	/@fs/proc/self/cmdline	Unknown	Direct	0	6c46e2ab-0746-4829-a37c-12b0ae5e23e4	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:51.659332
354	9f6cbf4b-88b6-4796-bd5e-b5059a567493	/@fs/proc/self/cmdline	Unknown	Direct	0	58aef7ae-8157-4a09-83a1-4eee6eadea30	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:51.828099
355	11b1f26c-3173-46a6-ba20-c257ec2b964c	/@fs/app/.env	Unknown	Direct	0	8999e6a9-3b70-4f7c-adf0-5d737f8e7af5	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:51.999608
356	3e2aac0d-4b61-420c-b858-2b4dfbecdc61	/@fs/app/.env	Unknown	Direct	0	5b17c48b-ef5b-4193-83b2-0798572207df	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:52.16863
357	0c6d0f23-9cfd-41f8-a586-c65d0ba25311	/@fs/app/.env	Unknown	Direct	0	f67bbc4f-822a-4ec2-babd-02e72cb773bb	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:52.344379
358	a3dabc97-668c-432b-9d19-b416bf672976	/@fs/app/.env	Unknown	Direct	0	03447249-55f3-4b93-8256-d20283141138	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:52.511961
359	0ec32fa5-afa1-4929-9a8f-2b56219bfe95	/@fs/app/.env.local	Unknown	Direct	0	382716ce-c990-4819-a12f-4836ce2f8e93	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:52.678769
360	3ae52c6e-5193-40b7-a31c-1021aec6244e	/@fs/app/.env.local	Unknown	Direct	0	69399560-363f-430c-9504-c144e42708d3	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:52.845548
361	94187e40-9fcc-451d-8279-55757174dcf4	/@fs/app/.env.local	Unknown	Direct	0	d118625c-a56e-4f27-8250-a529b1270f69	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:53.014389
362	76242a2d-d6a0-406a-b758-eb4aca238d00	/@fs/app/.env.local	Unknown	Direct	0	ad7e7796-9406-4493-931f-3f2e806dc854	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:53.189554
363	e5d0ecb9-f14c-4470-89e0-1ef27d63fe73	/@fs/app/.env.production	Unknown	Direct	0	5c4a2b08-23ab-452c-ba10-9837cddef633	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:53.353168
364	e7d41253-dbb1-45b1-b9fd-24ce16040913	/@fs/app/.env.production	Unknown	Direct	0	4aeb747e-1397-4b12-bd4f-8e0c62fc894a	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:53.52512
365	b2853330-d9af-4047-8bdc-db951ce5f569	/@fs/app/.env.production	Unknown	Direct	0	8d26a25b-8c57-463a-864a-d6201aca4982	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:53.69476
366	268bf177-4ebb-4a32-9b14-678f87a3d8c2	/@fs/app/.env.production	Unknown	Direct	0	c80d4e37-d54c-4295-a8f1-0562afaa519e	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:53.85854
367	949f9f3f-816c-4939-9c4d-3f64d2059556	/@fs/app/.env.development	Unknown	Direct	0	4b4019a5-1731-4f68-8aea-441a6a6c1914	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:54.02475
368	c1b576a1-651b-4f8b-b3f6-4bd379bb70a3	/@fs/app/.env.development	Unknown	Direct	0	9b7b84b7-7921-4531-9a2d-760d97d867bb	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:54.191499
369	382d3df2-0339-4ca3-acb3-6f66dba079fb	/@fs/app/.env.development	Unknown	Direct	0	420356ac-b2d2-4684-bb53-0cb4cfe4d78b	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:54.358639
370	a107cc7f-c727-4d42-9143-d8e0bbccdd8f	/@fs/app/.env.development	Unknown	Direct	0	31277d44-6b4d-4ec2-8d09-8435b76b333f	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:54.525236
371	da60cb2b-c478-4a79-b9b9-44fb57e12aa9	/@fs/home/node/.env	Unknown	Direct	0	4adfa784-22fa-4be8-81d9-ba729c797e12	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:54.691653
372	70a4d6af-9c3b-4ee3-9411-ab0dafc0e8f6	/@fs/home/node/.env	Unknown	Direct	0	ba94571d-b6b4-424c-8da1-7674912af89d	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:54.860748
373	6a848a37-6f0a-47f0-b4d6-0ecab839fec2	/@fs/home/node/.env	Unknown	Direct	0	d0c88831-1b01-4537-99c4-6288c504385c	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:55.027537
374	2d0ca737-be55-4fff-8747-1c793db0e22e	/@fs/home/node/.env	Unknown	Direct	0	33aedf7b-2bc3-45f9-97b5-5ffc16b5f436	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:55.192634
375	93b3abfe-140c-4e9a-976b-ee0a9d5b4ca4	/@fs/root/.env	Unknown	Direct	0	60aa5620-736e-4be0-8b15-7cd7d5f237fb	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:55.355902
376	bb75eaa2-7cde-4193-b359-8dbe7236f265	/@fs/root/.env	Unknown	Direct	0	c8fb398a-0c60-4220-822b-a86475b2a828	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:55.520637
377	137f1d07-4231-4b37-a470-d25847c15fa6	/@fs/root/.env	Unknown	Direct	0	2124ed95-86e7-4a0a-975f-ec3bc55b501d	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:55.687763
378	e56798e4-2edb-4ac5-b9da-dee140509c32	/@fs/root/.env	Unknown	Direct	0	4a8dfe01-391b-4cb4-a624-e01e0e260a4f	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:55.853471
379	d13df28a-e47c-44ca-ac7f-848937672712	/@fs/app/config/default.json	Unknown	Direct	0	0afd0151-71eb-4928-84d3-5e384833a62c	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:56.021462
380	8dabad15-7b04-456b-b4d4-457392768d25	/@fs/app/config/default.json	Unknown	Direct	0	bb91fb87-e39b-4199-80dc-b81a63bd76c9	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:56.186882
607	3980b12b-7cfb-431e-bc72-935680390502	/wp-Blogs.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:37.7028
381	ac5c6375-50ea-4eb2-bee5-519a159dd4df	/@fs/app/config/default.json	Unknown	Direct	0	60002871-9322-4ad8-af34-7e4a72381daf	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:56.351346
382	cf183c45-a14a-43a8-ba18-2163427fa3f5	/@fs/app/config/default.json	Unknown	Direct	0	14284c4f-3a75-49ab-bf8b-a70ed67535c8	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:56.518755
383	d763708b-ffe5-451c-a084-f20d0a3fe320	/@fs/app/config/production.json	Unknown	Direct	0	72758010-70c9-4bf2-8d65-4cbedc11e6c0	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:56.69237
384	f1a297a3-d8d8-47fb-aa65-0a9d8451e4b4	/@fs/app/config/production.json	Unknown	Direct	0	4e4a0948-1896-4394-a06a-a287147442d3	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:56.859018
385	7a620232-e9b4-4f3f-9387-f1de42a18963	/@fs/app/config/production.json	Unknown	Direct	0	9ef36f95-ff95-48d5-9a42-ae44233d86e0	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:57.027526
386	ecc87528-986c-4f71-ab74-01d20d3cbbc0	/@fs/app/config/production.json	Unknown	Direct	0	f93ed698-4045-4910-9fa0-739f9fd2c8d3	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:57.194017
387	131fffba-acc7-4127-b055-101d7b6b40e7	/@fs/app/.npmrc	Unknown	Direct	0	1c71ff08-e8bd-463a-9c16-9653985dc177	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:57.364415
388	e3b51c87-7cf9-4f04-a703-cdbc56c7a191	/@fs/app/.npmrc	Unknown	Direct	0	86a65fa1-52fb-40a7-ad5a-a65c682dc7e1	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:57.532489
389	4ba34ebd-b51a-4496-887c-718db7c0fb65	/@fs/app/.npmrc	Unknown	Direct	0	e3542e04-e79f-42a9-899a-4031452d7073	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:57.701989
390	e2b69c90-72e6-48be-824b-e522761bae94	/@fs/app/.npmrc	Unknown	Direct	0	81c77438-f262-4ad7-bf5f-3471b5908624	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:57.867443
391	d6dc9363-77d2-4714-a551-e3db66c26b30	/@fs/app/vite.config.ts	Unknown	Direct	0	a22c524b-9710-4e5b-968a-cdc6a4658aa6	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:58.033685
392	5c4850da-241a-4cb9-bf3c-827acaa68ba6	/@fs/app/vite.config.ts	Unknown	Direct	0	48cf30e2-5ed3-4806-a2fc-30512bf2a8db	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:58.201603
393	3646b899-d92a-4a92-a789-8b0c07ac3d00	/@fs/app/vite.config.ts	Unknown	Direct	0	c343e8e3-f90e-4be8-bec1-cc415f4f1826	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:58.367259
394	10758c18-6da8-49c7-b6b8-b98ec2add148	/@fs/app/vite.config.ts	Unknown	Direct	0	a8e99183-6165-42e8-8371-5947c91cfb51	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:58.549657
395	ba5cfc29-958a-4259-a36e-18cd8ff6bf6a	/@fs/app/vite.config.js	Unknown	Direct	0	9b44c6bc-58c7-461f-8974-140465bd53f5	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:58.720563
396	cd713f9c-9f33-40e6-b329-a749d1f691b9	/@fs/app/vite.config.js	Unknown	Direct	0	0270c2c9-1075-4f5d-b5ee-8574654962e8	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:58.884473
397	a92ace81-ff1b-4194-b3db-6294ebfc11fd	/@fs/app/vite.config.js	Unknown	Direct	0	29d3bd0d-9313-44c3-aba8-a41c45bd9ec7	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:59.055754
398	a4950bf1-fe0f-4743-8559-96078b33e3fb	/@fs/app/vite.config.js	Unknown	Direct	0	3d1dcf5c-4c96-4a5e-9307-bcaac583cd7b	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:59.2261
399	f8a57d89-7714-4100-99dc-4517849155de	/@fs/app/docker-compose.yml	Unknown	Direct	0	d24e78f4-b989-4994-ad9e-dff53b2191c3	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:59.39952
400	89a1dfd5-f2ef-4650-81ff-d0834e707bf8	/@fs/app/docker-compose.yml	Unknown	Direct	0	56b28be3-759e-4cb6-af1f-ac1cabe5a4ed	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:59.567655
401	901ca61f-eb97-416e-9867-e56c2d743168	/@fs/app/docker-compose.yml	Unknown	Direct	0	456d7dde-e508-4847-b4f1-ae1248291498	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:59.755792
402	e3869ce3-1073-4ab3-98c9-ae95fc6b18ec	/@fs/app/docker-compose.yml	Unknown	Direct	0	e06a34db-33a4-405f-83c5-68d6c67d75a4	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:36:59.92589
403	44179de7-5b68-45b4-be25-697fc538b03f	/@fs/app/Dockerfile	Unknown	Direct	0	0ae120a9-a8f8-4671-8e45-315d7b2fa7ae	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:00.089706
404	eccf0322-0c83-4d83-866f-3e7febeaf035	/@fs/app/Dockerfile	Unknown	Direct	0	79752a87-be1d-4fc7-a6b2-d25a9106c984	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:00.253582
405	afd77117-5d3d-4ee7-9be5-d9894c81274a	/@fs/app/Dockerfile	Unknown	Direct	0	49eb1cb9-6f5d-46b7-94b1-12caf8d92ce1	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:00.419846
406	7de65b58-3f21-485a-b8fb-a9f05e1e2dfc	/@fs/app/Dockerfile	Unknown	Direct	0	8f8ebf96-5080-4803-8239-2575fe6e6e1e	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:00.585215
407	af8b0052-7879-43ed-b0bf-2750cd6b8cb2	/@fs/home/node/.bash_history	Unknown	Direct	0	980853b8-9e76-427c-b7c3-a4cdee146e95	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:00.750379
408	f05478a3-2bac-4e6e-b386-33b7771dcbcb	/@fs/home/node/.bash_history	Unknown	Direct	0	b28d2f84-2796-4b32-b36d-dfed6e89b9e5	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:00.916536
409	393fb124-98b7-4d51-8d2f-ad1fb10e9705	/@fs/home/node/.bash_history	Unknown	Direct	0	e5e3bbf6-818d-48de-b99a-c03c01ea9739	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:01.082798
410	5a44d90f-6e23-4d2b-890a-dab55dd8c94d	/@fs/home/node/.bash_history	Unknown	Direct	0	25ad9f6a-cd26-4fbd-8c67-1b990e3a7215	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:01.248314
411	f357c7ad-085f-433d-a39c-681799289ae5	/@fs/root/.bash_history	Unknown	Direct	0	0b34eca4-abc0-44c6-84c8-10191c503f73	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:01.419227
412	7c8e60ee-aa7c-4df2-aeb1-01ab416460c3	/@fs/root/.bash_history	Unknown	Direct	0	d35a9b51-25a5-40de-a4b5-7eddbd5c9748	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:01.589901
413	2ed958ff-cb09-491c-ad86-dd41aa3cea2c	/@fs/root/.bash_history	Unknown	Direct	0	887e05d7-fff5-4ba7-a2a6-347405893c00	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:01.754744
414	2b9b1c88-bbff-4f79-b572-60f4b736cb16	/@fs/root/.bash_history	Unknown	Direct	0	3b3b894d-8b07-42e4-81ba-cc4b68c49673	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:01.922651
415	88312611-aa09-4738-898b-30dda48e37a6	/@fs/home/node/.bashrc	Unknown	Direct	0	d25e8218-f004-4754-a1b5-b154b251bf50	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:02.086891
416	da583325-a085-4f8e-bdad-a5b99e582c23	/@fs/home/node/.bashrc	Unknown	Direct	0	0c929003-97ad-4798-be43-aac749b31c18	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:02.25101
417	786d0a4f-2df0-4235-9f77-93ce089f1326	/@fs/home/node/.bashrc	Unknown	Direct	0	5250dd4f-5500-4860-b004-bafa2a48fff5	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:02.416098
418	c2f5f833-8a79-4591-97b8-3cc0be79d3d5	/@fs/home/node/.bashrc	Unknown	Direct	0	1596b0c3-96bf-4ebf-b0df-c3c1b21471c0	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	2026-05-09 19:37:02.581937
419	5cf3c945-d0a5-4b89-b07c-860def09478d	/forgot_password	forgot_password	Direct	0	15416dec-a3cc-4bac-bcfb-15da5ffe27fa	23.23.97.185	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amzn-SearchBot/0.1) Chrome/119.0.6045.214 Safari/537.36	2026-05-09 19:40:38.466892
420	c16f50ee-a915-4f28-bc4a-c15e4486c3bb	/	index	Direct	0	196a5e45-49f1-49b8-92e9-371229eec9d0	204.76.203.206	Mozilla/5.0	2026-05-09 19:41:39.100439
421	db6d2ce7-1422-4884-81d6-5afbe1cf7674	/forgot_password	forgot_password	Direct	0	b23312d5-6678-4d15-a56f-705077ad0022	54.197.241.196	Mozilla/5.0 AppleWebKit/605.1.15 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/605.1.15	2026-05-09 19:42:07.26284
422	6b397234-fa7c-444e-be79-925415e5c955	/	index	Direct	0	871a7ff0-a2c0-4a8c-8c8e-47f573002b97	204.76.203.206	Mozilla/5.0	2026-05-09 19:51:36.427329
423	96f8aadd-fce8-4ddf-b230-de270186cbae	/.env	Unknown	Direct	0	23130f28-14ff-4417-a8ea-c8f6a40b3535	45.38.78.226	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	2026-05-09 19:52:50.115785
424	d0040593-0b2f-4c66-bc0d-9cdce3752397	/	Unknown	Direct	0	04b8a143-d32b-4400-ab02-79f063ff510f	45.38.78.226	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	2026-05-09 19:52:50.991169
425	bf822b4c-8875-46a7-8616-f8aaa4236e83	/	index	http://gspaces.in	0	ad00063c-05df-4057-90ea-2ea650708c0c	101.32.208.70	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-09 19:54:24.952444
426	307cc576-b476-451d-b998-5583890159b3	/sitemap.xml	serve_sitemap	Direct	0	87a78df1-f3be-4f67-82d1-54b36c51cd44	2a03:2880:f806:13::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-09 19:57:14.039563
427	9559563f-6519-4bce-b8be-8ce6730cdf6f	/	index	Direct	0	2383b3d4-6e42-4a63-a10e-6f0fb188ef41	204.76.203.206	Mozilla/5.0	2026-05-09 19:57:25.096196
428	8e7e03b6-aae5-4124-b092-8ea3c5c0b9e1	/news_sitemap.xml	Unknown	Direct	0	5fce54c5-43de-4832-a858-1f116d1c81fa	2a03:2880:f806:51::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-09 20:04:05.467334
429	7cfda39a-fd37-43d0-b64a-4b0237464bd5	/	index	Direct	0	9a7b58cb-3313-4dd8-a8fd-e2b9bc2e03a5	204.76.203.206	Mozilla/5.0	2026-05-09 20:05:21.887268
430	0beeb4fd-35d7-44fa-9039-7586b6600119	/edit_sub_image/122	Unknown	Direct	0	5f9e055d-c900-404e-ba57-83e738e5ef37	92.222.108.96	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-09 20:05:54.223589
431	72f9bfac-6b41-41d1-a2c5-fc5d7972200d	/product/25	product_detail	Direct	0	bfcb8d88-86f1-4907-a95d-a650adf2d182	98.84.242.117	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amzn-SearchBot/0.1) Chrome/119.0.6045.214 Safari/537.36	2026-05-09 20:14:58.717292
432	897fa2c4-c684-43dd-ab42-e44eabb40b83	/product/23	product_detail	Direct	0	dd8ed6b6-95e0-4a6a-8b41-a3f63d3f9be0	35.168.48.89	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amzn-SearchBot/0.1) Chrome/119.0.6045.214 Safari/537.36	2026-05-09 20:15:08.705082
433	51aa7895-4073-49e5-8fcc-ee27d81bd15a	/my-workspace	my_workspace	Direct	0	c8555030-107f-4a56-894c-c45d1fa5e2b9	170.106.192.3	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-09 20:15:57.23984
434	577bb2c0-dc27-4149-b172-3f03536ae5d3	/login	login	https://gspaces.in/my-workspace	0	2beee96e-dd3d-4409-b5aa-9dbc362865d7	170.106.192.3	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-09 20:15:58.386539
435	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/	index	Direct	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:16:43.402853
436	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/orders	admin_orders	https://gspaces.in/	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:16:45.805381
437	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/orders	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:16:47.468246
561	bd13d47b-0e69-4879-ae4a-ca69c4ef0ff9	/	index	Direct	0	40d88787-4f4a-46cc-8755-55f34163cead	66.228.53.46	Mozilla/5.0 (Macintosh; Intel Mac OS X 13_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36	2026-05-10 00:59:57.590866
438	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:16:52.293014
439	e080469a-ac8a-4bb7-a636-4695191421c8	/privacy	privacy	Direct	0	ab3468a3-d65b-4268-8735-7da96f522d67	37.59.204.130	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-09 20:17:07.534705
440	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:18:05.61001
441	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/10/edit	leads.edit_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:18:06.209831
442	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/leads/10/edit	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:18:09.954691
443	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:18:12.79285
444	4313dc9d-3434-4ad3-a553-b9cc80f54dad	/	index	Direct	0	7a1792cd-dd46-4267-9140-af5bab152d65	204.76.203.206	Mozilla/5.0	2026-05-09 20:18:34.825005
445	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/leads/10/edit	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:18:36.840079
446	c67fe569-0903-440c-81ad-4d40b1e27a3f	/	index	Direct	0	f97f999e-4360-4b5c-9c5d-f05e2c1fde26	205.210.31.2	Hello from Palo Alto Networks, find out more about our scans in https://docs-cortex.paloaltonetworks.com/r/1/Cortex-Xpanse/Scanning-activity	2026-05-09 20:19:16.632775
447	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:21:12.470839
448	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:22:40.774325
449	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/11/edit	leads.edit_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:22:40.974298
450	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/leads/11/edit	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:23:55.059656
451	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:23:56.892903
452	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:24:45.930061
453	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/12/edit	leads.edit_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:24:46.124965
454	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/leads/12/edit	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:25:12.637075
455	3cc8bb22-8b37-4870-a10e-0e1c9f6e5c5d	/	index	Direct	0	d161ed0c-66e6-444c-be35-d7155e4f2c56	204.76.203.206	Mozilla/5.0	2026-05-09 20:25:15.954586
456	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:25:23.13972
457	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:26:19.535132
458	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/13/edit	leads.edit_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:26:19.790184
459	f47ea3fc-6962-4fd4-932b-7742c7f5ad29	/uono/tatti-ka-game-40698t4.pdf	Unknown	Direct	0	99c04afa-3b4c-4b28-a4ba-d6a93ca0dee7	223.109.252.209	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-05-09 20:26:30.657528
460	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/leads/13/edit	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:26:51.551492
461	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:26:54.647795
462	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:27:39.65074
463	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/14/edit	leads.edit_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:27:39.848817
464	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/leads/14/edit	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:27:53.674587
465	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:27:57.224045
466	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:28:41.734532
467	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/15/edit	leads.edit_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:28:41.927893
468	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/leads/15/edit	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:29:18.895434
469	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:29:20.481099
470	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:29:51.222972
471	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/16/edit	leads.edit_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:29:51.48179
472	494925ab-ce7d-48fd-a055-a8f1b71f7401	/robots.txt	Unknown	Direct	0	d4c6159d-5c7d-49aa-a1cb-4693a0afc2c0	216.73.216.13	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)	2026-05-09 20:30:02.215236
473	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/leads/16/edit	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:30:14.313935
474	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:30:38.505325
475	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/create	leads.create_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:31:25.533797
476	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads/17/edit	leads.edit_lead	https://gspaces.in/admin/leads/create	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:31:25.802485
477	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/admin/leads	leads.admin_leads_list	https://gspaces.in/admin/leads/17/edit	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 20:31:38.107124
478	c50c78ea-28d1-4659-aa43-37132a409516	/	index	Direct	0	0a42a6f4-5a6e-4a35-8e10-8f54930381ad	204.76.203.206	Mozilla/5.0	2026-05-09 20:31:45.784857
479	9622e433-f0a4-4b24-9c32-a530f0ae8cf1	/sitemap.xml	serve_sitemap	Direct	0	733def5e-e0a3-43cc-9246-3b906dbdf4af	37.59.204.129	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-09 20:37:06.179771
480	2f61d8a4-7d64-4d79-9f20-ea917e35d1fc	/	index	Direct	0	a83a0509-b8e7-4894-b772-228652dfa5d1	204.76.203.206	Mozilla/5.0	2026-05-09 20:40:09.349397
481	56864e13-b519-4737-b3d8-ec322a51e131	/delete_sub_image/122	Unknown	Direct	0	5e44704f-de23-4f63-b33d-f6e85b12b322	37.59.204.143	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-09 20:47:33.847777
482	5e5084ba-8fd1-4820-9650-379990cab21c	/	index	Direct	0	8b90a4a1-0d75-44d0-9daa-1ab5deed2464	204.76.203.206	Mozilla/5.0	2026-05-09 20:50:33.929427
483	46522bf8-08cd-4d42-98d0-b2ba24e5f23b	/	index	Direct	0	fbc0c0bd-ad72-4e6d-8bd3-ce51c639f94a	43.130.105.21	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-09 20:52:22.377602
484	e85f5a2f-2d3d-4555-a02f-12926162595a	/	index	Direct	0	4c68b21e-59f6-4de9-bce2-df46753ab255	204.76.203.206	Mozilla/5.0	2026-05-09 20:59:41.005419
485	f96be018-1ad3-4a8a-930e-57bcd18664d9	/sitemap.xml	serve_sitemap	Direct	0	6dd20973-a5a2-4d89-9054-08bc94f02325	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	2026-05-09 21:00:12.027574
486	c52889a3-79e1-4512-9cf0-7444cb8b224d	/robots.txt	Unknown	Direct	0	69d7e42c-f5dd-4583-9444-5ff75a1d7b21	2a03:2880:f806:4::	facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)	2026-05-09 21:01:33.328516
487	200501b7-7871-4b3e-95d3-27076855d5de	/Core/Skin/Login.aspx	Unknown	Direct	0	1c2fc3db-98f6-4312-9af4-d552081a17be	43.129.169.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36	2026-05-09 21:01:36.202478
488	69bfbef0-37e4-465f-95b9-ad7e27be5d8d	/robots.txt	Unknown	Direct	0	fe5a8f75-5770-4d8a-919f-49ac6ed3532e	2a03:2880:f806:27::	facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)	2026-05-09 21:05:14.628275
489	c811c043-86f6-48d0-afd8-e7f5315d1b61	/shop.html	Unknown	Direct	0	a151e093-9b07-4fc4-89a8-0366ef4799f0	2a03:2880:f806:1::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-09 21:05:20.121756
490	b4460f42-03ad-42f6-96ac-3b3b88243329	/	index	Direct	0	3768ed76-0b36-4070-a7b3-132d8ab8fb15	204.76.203.206	Mozilla/5.0	2026-05-09 21:09:04.784317
491	125f78f9-de5b-4c26-b98b-516ac69203bd	/my-workspace	my_workspace	Direct	0	638a058b-b557-4a37-af43-101fa12ecccc	43.157.46.118	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-09 21:10:04.149883
492	a0cce080-621f-4109-99de-17c2de7e3c0d	/login	login	http://3.7.69.151:80/my-workspace	0	18c239ec-fd1a-4be3-becc-c6aaf708b2d5	43.157.46.118	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-09 21:10:05.855455
493	e5bf89cb-9d7e-4478-b74f-2942729d642e	/	index	Direct	0	94b13697-83e4-4e11-bb3c-e107cd6da4ec	204.76.203.206	Mozilla/5.0	2026-05-09 21:15:13.469268
494	87854063-5547-4a0b-aecd-9e8929a0ee31	/	index	Direct	0	b0984f42-4ff5-4731-a0cc-381c125e9ee3	135.237.126.203	Mozilla/5.0 zgrab/0.x	2026-05-09 21:24:06.569325
495	67618c28-0730-44a9-8bce-80f9e75c7713	/forgot_password	forgot_password	Direct	0	87210a27-aa0c-4a40-a921-d4d9653e5450	43.135.130.202	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-09 21:24:36.791338
496	b0a887f9-d753-4092-8e3f-c1fcae19e845	/	index	Direct	0	f2c2ecb5-d6cf-4c02-99b0-2065b6777c24	204.76.203.206	Mozilla/5.0	2026-05-09 21:25:05.87825
497	67e2e015-763c-4e77-abe3-76ff441ca003	/.env	Unknown	Direct	0	ac286f21-d05f-4514-adb4-1a603c3375dd	31.57.38.139	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.129 Safari/537.36	2026-05-09 21:28:48.027673
498	c174faf9-b8fa-4771-a3a5-3a980ce6574b	/	Unknown	Direct	0	165d1b22-d35f-4878-9237-4afcbfbfbdd3	31.57.38.139	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.129 Safari/537.36	2026-05-09 21:28:49.813243
499	4f01d8f7-cce8-4248-ad44-d6bc402c2e51	/	index	Direct	0	11229419-eebe-4245-aec7-109049efb4f9	204.76.203.206	Mozilla/5.0	2026-05-09 21:34:41.363604
500	e1d18f1a-a0e2-4454-af89-e487b21ea54b	/robots.txt	Unknown	Direct	0	f1da12b0-8281-4f80-9293-aee851d931da	103.190.47.118	Mozilla/5.0 (Macintosh; Intel Mac OS X 14_1_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.6668.58 Safari/537.36	2026-05-09 21:36:43.491094
501	d14bd570-aaa3-48fc-a188-bb60d2135f1f	/	index	Direct	0	f3ab6709-428a-465f-a08e-5e8fcf93280c	204.76.203.206	Mozilla/5.0	2026-05-09 21:49:28.545892
502	d2342932-59a8-4410-9571-44d1b8f53cae	/	index	Direct	0	db2a97ab-776e-4b4f-99e8-5f52105bcd69	204.76.203.206	Mozilla/5.0	2026-05-09 21:59:01.507675
503	4e0ab285-72dc-45c3-998b-7e57264afd62	/	index	Direct	0	2d49d51b-1ce2-4875-81e1-ee79295403d0	205.210.31.13	Hello from Palo Alto Networks, find out more about our scans in https://docs-cortex.paloaltonetworks.com/r/1/Cortex-Xpanse/Scanning-activity	2026-05-09 21:59:33.715778
504	a724e88a-69e6-4acf-b2f4-a9a40a5333f7	/online/best-casino-in-japan-apk-24575t48.pdf	Unknown	Direct	0	2d614ac3-12c4-4a32-9ef2-5953d35066fd	223.109.255.167	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-05-09 22:07:10.15646
505	d1fedb13-a341-49a0-bd68-b20668ad4268	/	index	Direct	0	a1a4fbe5-ebad-4a3a-9a81-ce86945ecbcc	204.76.203.206	Mozilla/5.0	2026-05-09 22:08:39.718867
506	09ec7c4d-d7da-4c44-b216-84221d83f03d	/	index	Direct	0	7f9fa46d-b779-40cb-97a3-d0b68193ef8d	192.154.102.34		2026-05-09 22:08:56.718136
507	f03b9cf0-17e0-4b3a-9767-4e6fe693616e	/sitemap.xml	serve_sitemap	Direct	0	391f3f6f-dc52-4da6-b85e-54c59d8fc457	94.23.188.212	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-09 22:16:03.384058
508	2952380c-44d2-4ca6-9e18-145ed6724be6	/	index	Direct	0	0351df76-4aeb-4bb1-8f78-e8f1df106844	204.76.203.206	Mozilla/5.0	2026-05-09 22:19:14.656865
509	82e1169f-8eec-481c-9347-7cc4dfeee466	/robots.txt	Unknown	Direct	0	34399f8d-e6bf-4889-a95b-55c97c0657ee	216.73.216.13	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)	2026-05-09 22:24:35.941918
510	faa57d67-f76c-48ef-9f4f-61e77ca127b7	/	index	Direct	0	fac78b6b-94a8-4c78-9a49-8014f9442e5e	204.76.203.206	Mozilla/5.0	2026-05-09 22:25:44.164967
511	c243002a-54ba-4d17-936f-dd711a0f242c	/	index	Direct	0	d65b197a-7010-4176-bb8c-00be193b189b	204.76.203.206	Mozilla/5.0	2026-05-09 22:35:25.644621
512	6c08eacc-bce3-4819-be17-e1e3f89d8d95	/Core/Skin/Login.aspx	Unknown	Direct	0	da5781d4-c5a5-47eb-8716-965065d8c62b	43.129.169.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36	2026-05-09 22:40:04.649002
513	636f7de6-972d-4dd5-8337-f168c1e16ce2	/robots.txt	Unknown	Direct	0	e2a75b7b-cde1-40bf-8d6f-ebf50eeaf962	98.88.179.76	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/600.2.5 (KHTML, like Gecko) Version/8.0.2 Safari/600.2.5 (Gort)	2026-05-09 22:42:28.961438
514	b0513bfb-3327-42fc-8b89-05ac04dfca1c	/	index	Direct	0	452a7190-88f8-4696-8109-12ce950d9a15	204.76.203.206	Mozilla/5.0	2026-05-09 22:43:34.099882
515	dbd25cae-e8c5-48d2-ae82-d165f1a7ddf4	/sitemap.xml	serve_sitemap	Direct	0	30c3565f-f11d-4861-aae8-d233dd93a8fa	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	2026-05-09 22:53:20.592819
516	89991a33-e30f-410e-8902-ccb6e770ff44	/	index	Direct	0	f6af4d3c-f0ef-4934-8978-a688c4c79c82	204.76.203.206	Mozilla/5.0	2026-05-09 22:54:42.161738
517	edf7da4f-716a-4c64-ad68-01e21da6fcd2	/wp-login.php	Unknown	Direct	0	fa9057eb-f8fb-4b69-a780-8519ea06d930	216.73.160.46	Mozilla/5.0	2026-05-09 22:57:30.925814
518	2a127c07-3281-44ee-b736-730305b5efcf	/online/badminton-olympic-india-apk-25701t6.pdf	Unknown	Direct	0	50786c80-8a71-4afa-b247-79b2a52cfd51	112.86.225.21	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	2026-05-09 23:06:29.810325
519	09f15177-b280-44a2-94de-1826596d0e3d	/	index	Direct	0	e44d5878-78a0-4f5d-98b9-2d7c902932a1	204.76.203.206	Mozilla/5.0	2026-05-09 23:09:41.751952
520	677926a1-5545-4d9a-a35e-0d9233d26e03	/	index	Direct	0	3d39ea0f-b253-4afd-b0b9-7182fee87349	204.76.203.206	Mozilla/5.0	2026-05-09 23:19:37.432727
521	4944aab0-73eb-4586-9ffc-00cc499ed544	/	index	https://gspaces.in/	0	afadd75c-4ee7-415e-b60b-99f022cee245	94.176.54.57	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:150.0) Gecko/20100101 Firefox/150.0	2026-05-09 23:19:53.371969
522	6c3423fe-d093-411d-8d20-b56031f5dd56	/	index	Direct	0	95e2b788-08a0-46ef-914f-1138d456b1bc	162.243.212.67	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	2026-05-09 23:19:53.377735
523	5c911659-4b0f-49d3-9cbd-075f588a2263	/	index	https://gspaces.in/	0	cbfba894-7933-4075-bac7-fd51a908dc49	206.204.50.44	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15	2026-05-09 23:19:53.379384
524	95251b02-ffb0-4175-9256-71a35fb9cb1a	/	index	https://gspaces.in/	0	2032e482-7e00-4547-a834-c8e1542c9b75	159.203.88.57	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15	2026-05-09 23:19:53.381271
525	1db50ade-624a-41b1-8794-26017684ce5a	/	index	https://gspaces.in/	0	ca67dc92-3a7e-4d65-b578-f95455768c26	157.245.220.98	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:150.0) Gecko/20100101 Firefox/150.0	2026-05-09 23:19:53.501773
599	3980b12b-7cfb-431e-bc72-935680390502	/de.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:36.287309
526	309779ad-41bb-489f-80df-0efa9c865171	/	index	https://www.google.com/	0	219befb2-6c06-4e49-8844-ece9305f9f31	99.20.133.102	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-09 23:19:53.527691
528	459a78bd-37d6-4878-b7ba-5ce77b40ae58	/	index	Direct	0	d8305768-323f-475c-8471-b3cefcbd2482	45.76.165.95	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 23:19:53.530122
529	b2b4ea0f-177d-4ae0-83fa-75674db3d8ef	/	index	Direct	0	be40c4c1-f5c4-4fdb-b1dd-fbe50721f9a9	173.168.78.74	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 23:19:53.668091
530	62f7cd07-0eb4-4973-8259-a4457b4a8e4f	/	index	Direct	0	0e6ed86d-401d-40b1-9977-66853a2215f1	129.222.143.94	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	2026-05-09 23:19:53.670842
531	f320934b-6bc3-440e-b200-20b5f0eed2e9	/	index	Direct	0	d5ba0d3d-da90-4639-977f-c0bf2502a37b	161.123.78.103	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-09 23:19:53.681136
532	c47ff837-64aa-4785-b1da-1f6a73a716ff	/	index	https://gspaces.in/	0	cbe5b95f-3ba9-4cde-9435-d6565e313e5d	67.248.87.82	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:150.0) Gecko/20100101 Firefox/150.0	2026-05-09 23:19:53.687522
533	d32c28e8-8a52-493d-8b8b-af103784e06f	/	index	https://gspaces.in/	0	bd02289f-b22f-42a3-8ff0-b141ffa756af	24.151.161.223	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15	2026-05-09 23:19:53.793414
534	884915a7-aa3f-480d-a719-98d2dbeaecc1	/	index	https://www.google.com/	0	7dcc0080-4dee-4c30-8553-2c029c1029aa	176.223.106.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	2026-05-09 23:19:53.797913
535	67c8373b-6dc4-4563-bd13-a15de66e9b14	/	index	Direct	0	9c6b7712-6a97-4745-b952-6e0a3feefd75	204.76.203.206	Mozilla/5.0	2026-05-09 23:28:16.847011
536	20b6e6c1-b478-4bc4-8c32-ec9fc39f9877	/	index	Direct	0	e98535dc-303a-414b-9de3-7c66a14fdf02	204.76.203.206	Mozilla/5.0	2026-05-09 23:38:19.665701
537	857c9460-b333-4e47-91a6-e74e07a35481	/	index	Direct	0	cba345bb-60a5-48a7-9797-1482e4b115e8	204.76.203.206	Mozilla/5.0	2026-05-09 23:45:02.847879
538	906b59ab-cb00-4e31-8a1e-848a767631d1	/robots.txt	Unknown	Direct	0	c09f7ec0-9b50-4a6c-b607-96ae3b3d3414	92.222.108.120	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-09 23:48:26.242323
539	cbf108fc-8f72-4cc1-97c0-98bd5bdc4ac0	/sitemap.xml	serve_sitemap	Direct	0	a8b2f5e3-1948-4aa2-a1ed-13e2d07b635a	92.222.108.113	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-09 23:48:27.626336
540	3fafde58-1311-4609-8514-9f25e470fc55	/	index	Direct	0	31a16e2a-8fbd-4c8d-b2ba-b3e7b2d74362	204.76.203.206	Mozilla/5.0	2026-05-09 23:54:51.262966
541	dd2ebb44-3408-4b0d-bc8b-646dfcb24aec	/	index	Direct	0	698aed30-0565-48a6-b60c-207d520be2c6	204.76.203.206	Mozilla/5.0	2026-05-10 00:01:52.775759
542	7e8b20b1-5215-4f7c-95a3-2c351703a055	/	index	Direct	0	c6bd1394-4d99-436e-895f-74d889a728df	204.76.203.206	Mozilla/5.0	2026-05-10 00:14:24.385132
543	a8424117-647a-42d9-933e-c536ad9810fd	/Core/Skin/Login.aspx	Unknown	Direct	0	d19b712a-685c-46cb-8b1b-5d8d4a46b303	43.129.169.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36	2026-05-10 00:18:26.655935
544	96ce8e1b-6df9-4253-9686-c26e6cb7262f	/product/10	product_detail	Direct	0	82d2f187-978f-43b3-89d3-a860f410dc74	2a03:2880:f806:21::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-10 00:18:27.578935
545	ed5adbb1-c218-4f11-be2e-b7d1aa595f32	/about	about	Direct	0	bc1f5faa-5e99-4c1a-b2ea-ed8a9411908e	2a03:2880:f806:1::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-10 00:23:17.670957
546	87beabf3-f5b6-4be6-91fe-3529d5e5ac2e	/	index	Direct	0	8437636e-9d13-47e7-a90f-41374d1d5454	204.76.203.206	Mozilla/5.0	2026-05-10 00:26:42.525894
547	f78c3204-49f3-4d82-b926-4e6c8109cc3b	/xmlrpc.php	Unknown	Direct	0	9c892c04-ecb7-4b2c-9b88-dd5f9fd5e863	161.0.60.2	Mozilla/5.0 (X11; Ubuntu; Linux x86_64; arm64) AppleWebKit/537.36 (KHTML, like Gecko) Opera/73.0.0.0 Safari/537.36	2026-05-10 00:33:42.330317
548	62a22507-ffe3-4c13-85c5-1b55e1529f88	/robots.txt	Unknown	Direct	0	96637cd1-a8e4-4555-8c5c-37195829acb6	216.73.216.13	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)	2026-05-10 00:34:07.401966
549	b404cb35-c682-43a7-be0e-39804521a4ad	/	index	Direct	0	2973b7e8-d236-45b4-85d4-f5d97acab586	167.172.187.227	Mozilla/5.0 (X11; Linux x86_64; rv:142.0) Gecko/20100101 Firefox/142.0	2026-05-10 00:36:06.807155
550	b0ff7765-2c90-4752-8776-32920b73d500	/	index	Direct	0	b66b2771-4d0e-4d3e-b970-fcc59f445e50	204.76.203.206	Mozilla/5.0	2026-05-10 00:38:47.169948
551	555f9dd8-f1eb-41a5-bbcf-6faa4806df19	/.env	Unknown	Direct	0	5bcfdd32-935f-45c8-a7fb-15063155154a	46.202.224.81	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	2026-05-10 00:46:50.724331
552	3fe4fba7-3cc1-4862-b14b-d67afdb133a3	/	Unknown	Direct	0	0e8f5573-00d6-4334-98d1-99757ba5577c	46.202.224.81	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	2026-05-10 00:46:51.761102
553	9e44bb69-738f-4f86-88db-52bf38614185	/	index	Direct	0	cc64a203-3cf3-4f1e-8ffe-e464113706bc	204.76.203.206	Mozilla/5.0	2026-05-10 00:48:11.471768
554	ebea27b8-3987-4354-8791-5a80387acf8c	/	index	Direct	0	a18035b0-9af1-4ad6-948e-2e44b4dadf14	145.239.71.235	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	2026-05-10 00:49:09.865129
555	ebea27b8-3987-4354-8791-5a80387acf8c	/customers	customer_inquiry_page	https://gspaces.in	0	a18035b0-9af1-4ad6-948e-2e44b4dadf14	145.239.71.235	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	2026-05-10 00:49:13.712222
556	1ac1da20-eae1-4014-85cb-b805e6a78b71	/wp-login.php	Unknown	Direct	0	97e5ed4f-8017-4a13-8992-8d4656c14ffa	172.98.33.248	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.6167.85 Safari/537.36	2026-05-10 00:53:16.99479
557	07237918-766c-4f89-9ab5-62d9e047e9ff	/administrator/	Unknown	Direct	0	f5ac3ded-8cc2-4dde-a2d5-d0a93e97a01a	136.144.43.211	Mozilla/5.0 (Windows NT 11.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.6167.85 Safari/537.36	2026-05-10 00:53:17.852032
558	0d44eb87-94e0-45a0-877e-77a0ba952dd1	/	index	Direct	0	18a1ce32-388c-4e4e-ac79-7a36fb597920	204.76.203.206	Mozilla/5.0	2026-05-10 00:54:55.481786
559	03bdc66e-9917-4d82-8d94-03230805b44e	/	index	Direct	0	2267d92d-5646-46ff-9dda-12e7d3193b85	145.239.71.235	Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0	2026-05-10 00:59:49.568603
560	03bdc66e-9917-4d82-8d94-03230805b44e	/customers	customer_inquiry_page	https://gspaces.in/	0	2267d92d-5646-46ff-9dda-12e7d3193b85	145.239.71.235	Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0	2026-05-10 00:59:53.476315
600	3980b12b-7cfb-431e-bc72-935680390502	/.dela.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:36.462391
562	b3e8fa31-d2b1-4ae7-a75b-35540438d69d	/.well-known/apple-app-site-association	Unknown	Direct	0	1c29edb0-5a62-40a3-bbb8-2da6e09f5f94	74.125.216.7	Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.7727.137 Mobile Safari/537.36 (compatible; AdsBot-Google-Mobile; +http://www.google.com/mobile/adsbot.html)	2026-05-10 01:01:56.318619
563	0d43db73-cee9-42e3-b7e6-ffd5de04db48	/	index	Direct	0	cc399554-5987-4917-8a9e-6ec1f2bf7fdc	204.76.203.206	Mozilla/5.0	2026-05-10 01:03:47.458676
564	2dd73caf-3f13-4504-bd4d-899027abbb09	/sitemap.xml	serve_sitemap	Direct	0	553b02fb-d0f9-4504-89f0-73fe78d369f0	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	2026-05-10 01:06:20.498065
565	3fdd55d6-796c-42e5-b84b-543923fed79a	/	index	Direct	0	5c322b0d-3603-4f44-b590-b6da1f313532	204.76.203.206	Mozilla/5.0	2026-05-10 01:13:09.221571
566	9f0db4a5-e445-4b61-83ff-95a14e357628	/	index	Direct	0	4fb5a972-2874-488f-83fb-4db37079d6d0	118.194.228.167	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0	2026-05-10 01:18:18.821404
567	504f76e1-cf18-4cff-ab78-597bdd584f21	/robots.txt	Unknown	Direct	0	4555eb06-e9bc-4c35-be03-9b2fb4b13391	118.194.228.167	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0	2026-05-10 01:18:38.790264
568	51e75f13-ab07-496a-8e8f-04ca118dfec4	/sitemap.xml	serve_sitemap	Direct	0	92e4f4fa-239f-4dab-912a-b24c1f7ebb03	118.194.228.167	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0	2026-05-10 01:18:39.35362
569	9eddf26a-bcb9-42ba-84a8-a2157c169181	/config.json	Unknown	Direct	0	f048bd90-ae97-4bc9-a45b-96a488da75b9	118.194.228.167	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.56 Safari/535.11	2026-05-10 01:18:41.884174
570	cd577a1e-f7c5-42c7-a085-441d21832727	/sitemap.xml	serve_sitemap	Direct	0	b1e9fa33-9382-4841-af5a-63034afced36	94.23.188.219	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-10 01:18:44.283365
571	7bbdffa3-240c-4cb7-a5a2-ccba9f33a598	/GponForm/diag_Form	Unknown	Direct	0	00bc0fed-aa35-4283-81ce-ac60e1b6ea4e	103.151.226.38	Hello, World	2026-05-10 01:21:28.196587
572	36857180-3cf4-4e23-86e2-4770d38ebbcd	/	index	Direct	0	e08b834e-9e9c-4cad-9d9b-c6598212c335	204.76.203.206	Mozilla/5.0	2026-05-10 01:21:56.308227
573	717427c7-649f-4f59-aadb-fc5d99e96a51	/	index	Direct	0	5b159c3e-b5d7-415b-9791-b680016edcde	167.99.149.55	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/118.0	2026-05-10 01:26:10.56153
574	2b9185a3-464c-497d-8a83-6d500f1eec0c	/	index	Direct	0	e8fd4d05-7658-44bb-8a92-52c6426c9fed	204.76.203.206	Mozilla/5.0	2026-05-10 01:32:52.898173
575	f4cb137d-5cd3-436e-a4de-c430a1739587	/product/25	product_detail	Direct	0	742a9148-92bb-4b14-ae64-6bd2e9e5653b	2a03:2880:f806:1e::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-10 01:38:36.56748
576	702f4b7c-26f7-4e7e-a7cf-7c8916b6ce92	/	index	Direct	0	844389ba-ea6d-40fc-9198-6c56e721102d	204.76.203.206	Mozilla/5.0	2026-05-10 01:48:29.640972
577	c38d9733-0114-4b97-9c1c-140fb3be9a18	/apple-app-site-association	Unknown	Direct	0	91333dc4-a2f0-4bb3-8e03-950bdfa8a749	74.125.216.6	Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.7727.137 Mobile Safari/537.36 (compatible; AdsBot-Google-Mobile; +http://www.google.com/mobile/adsbot.html)	2026-05-10 01:53:04.459199
578	9ada0c09-0f02-4670-af59-2ff9f3ce72c3	/	index	Direct	0	3741f738-dd49-4e17-b322-9c3cbbbaf284	47.254.84.190	curl/7.64.1	2026-05-10 01:56:10.476742
579	66e1d694-a7f3-420c-92cb-0569b2bc8c86	/	index	Direct	0	2b5af99c-452a-4745-bb27-082c2dc97955	47.254.84.190	curl/7.74.0	2026-05-10 01:56:11.341815
580	ad16cd93-88d5-4a69-b1c7-fe96b5898eaa	/	index	Direct	0	c4d35deb-906a-4707-a1e3-3c4041b092a5	204.76.203.206	Mozilla/5.0	2026-05-10 01:57:06.067764
581	6f277864-8e81-43a6-bed6-65cb91f9fb39	/	index	Direct	0	c2bc595e-34e4-4b03-a15f-5d46eb33dc75	204.76.203.206	Mozilla/5.0	2026-05-10 02:06:41.923609
582	56dec003-5219-4785-810f-9b982c9b9a0b	/	index	Direct	0	a9d335b8-8c89-427b-b370-7eeaad184d73	204.76.203.206	Mozilla/5.0	2026-05-10 02:17:02.693641
583	90041d89-1e3f-481e-a1c9-b69dd4433b41	/product/9	product_detail	Direct	0	ecf3cbf8-d650-468a-b78b-ae8635508a8c	2a03:2880:f806:3e::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-10 02:21:56.189086
584	a13f396d-ef90-47e8-a0d3-9c24f7064dc4	/	index	Direct	0	5c5c136d-b49b-4713-afd2-e7ac67cdcc3a	204.76.203.206	Mozilla/5.0	2026-05-10 02:22:28.741753
585	a0bc56b1-9fcd-4ee0-ad45-52f1e8a9e756	/	index	http://www.gspaces.in	0	f9b49df7-84d2-4464-95ea-a41177a1b2aa	43.135.182.43	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-10 02:22:31.440952
586	e0263c2e-90d5-4ccc-ae32-65be286e0778	/	index	Direct	0	3aa7d444-8cea-409d-8781-c004bf01583b	43.135.130.202	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-10 02:23:36.783166
587	6e463cde-1945-45ed-990f-7376efee51b6	/admin/config.php	Unknown	Direct	0	a19eadd1-9487-40f5-9a9d-54e740654078	167.250.224.25	xfa1	2026-05-10 02:23:46.946718
588	993ec7b1-3d9c-4fbd-9958-3bb1714383ab	/signup	signup	Direct	0	3bb3ccac-52e5-4de6-bdca-adf47840e416	2a03:2880:f806:f::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-10 02:27:46.751243
589	bf58d6bc-36e6-42d0-8964-950e56019a12	/robots.txt	Unknown	Direct	0	7c89a314-8dd4-4c2f-8bc5-24bd44529f2b	216.73.216.13	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)	2026-05-10 02:28:33.845407
590	3980b12b-7cfb-431e-bc72-935680390502	/wp-content/plugins/hellopress/wp_filemanager.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:34.452154
591	3980b12b-7cfb-431e-bc72-935680390502	/seo.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:34.882234
592	3980b12b-7cfb-431e-bc72-935680390502	/wmore1.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:35.054409
593	3980b12b-7cfb-431e-bc72-935680390502	/wpb.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:35.231304
594	3980b12b-7cfb-431e-bc72-935680390502	/bgymj.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:35.401696
595	3980b12b-7cfb-431e-bc72-935680390502	/bhm.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:35.572646
596	3980b12b-7cfb-431e-bc72-935680390502	/maxro.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:35.749817
597	3980b12b-7cfb-431e-bc72-935680390502	/1.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:35.922742
598	3980b12b-7cfb-431e-bc72-935680390502	/wp-upload.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:36.119152
608	3980b12b-7cfb-431e-bc72-935680390502	/multirole.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:37.882847
609	3980b12b-7cfb-431e-bc72-935680390502	/aevly.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:38.056966
610	3980b12b-7cfb-431e-bc72-935680390502	/un.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:38.231044
611	3980b12b-7cfb-431e-bc72-935680390502	/themes4.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:38.408646
612	3980b12b-7cfb-431e-bc72-935680390502	/vx.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:38.580871
613	3980b12b-7cfb-431e-bc72-935680390502	/zxcs.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:38.76189
614	3980b12b-7cfb-431e-bc72-935680390502	/zvz89.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:38.937244
615	3980b12b-7cfb-431e-bc72-935680390502	/export.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:39.111325
616	3980b12b-7cfb-431e-bc72-935680390502	/as.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:39.285853
617	3980b12b-7cfb-431e-bc72-935680390502	/disagrsxr.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:39.460835
618	3980b12b-7cfb-431e-bc72-935680390502	/blox.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:39.635657
619	3980b12b-7cfb-431e-bc72-935680390502	/ckk.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:39.813086
620	3980b12b-7cfb-431e-bc72-935680390502	/bjeni.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:40.027053
621	3980b12b-7cfb-431e-bc72-935680390502	/cilng.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:40.199228
622	3980b12b-7cfb-431e-bc72-935680390502	/xx.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:40.374029
623	3980b12b-7cfb-431e-bc72-935680390502	/raw.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:40.555293
624	3980b12b-7cfb-431e-bc72-935680390502	/class-bda.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:40.725575
625	3980b12b-7cfb-431e-bc72-935680390502	/xxc.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:40.915339
626	3980b12b-7cfb-431e-bc72-935680390502	/like.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:41.098121
627	3980b12b-7cfb-431e-bc72-935680390502	/f222.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:41.270383
628	3980b12b-7cfb-431e-bc72-935680390502	/zz.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:41.447006
629	3980b12b-7cfb-431e-bc72-935680390502	/haz.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:41.617178
630	3980b12b-7cfb-431e-bc72-935680390502	/class-wp-image.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:41.795247
631	3980b12b-7cfb-431e-bc72-935680390502	/24name.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:41.969958
632	3980b12b-7cfb-431e-bc72-935680390502	/rasse.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:42.140509
633	3980b12b-7cfb-431e-bc72-935680390502	/zzx.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:42.31166
634	3980b12b-7cfb-431e-bc72-935680390502	/bootstrap.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:42.48372
635	3980b12b-7cfb-431e-bc72-935680390502	/class-cc.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:42.660551
636	3980b12b-7cfb-431e-bc72-935680390502	/667.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:42.837366
637	3980b12b-7cfb-431e-bc72-935680390502	/55l453.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:43.010136
638	3980b12b-7cfb-431e-bc72-935680390502	/sd.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:43.185591
639	3980b12b-7cfb-431e-bc72-935680390502	/wp-su.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:43.360112
640	3980b12b-7cfb-431e-bc72-935680390502	/rea889y.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:43.534138
641	3980b12b-7cfb-431e-bc72-935680390502	/wp-act.php	Unknown	Direct	0	edd60de5-21b2-4868-b51a-35a6d347632f	20.123.33.13		2026-05-10 02:28:43.714368
642	57a7945c-9581-444c-b4a3-464cd45b6e07	/wp-content/plugins/hellopress/wp_filemanager.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:09.070642
643	57a7945c-9581-444c-b4a3-464cd45b6e07	/seo.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:09.243765
644	57a7945c-9581-444c-b4a3-464cd45b6e07	/wmore1.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:09.416804
645	57a7945c-9581-444c-b4a3-464cd45b6e07	/wpb.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:09.602012
646	57a7945c-9581-444c-b4a3-464cd45b6e07	/bgymj.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:09.816303
647	57a7945c-9581-444c-b4a3-464cd45b6e07	/bhm.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:09.99416
648	57a7945c-9581-444c-b4a3-464cd45b6e07	/maxro.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:10.246441
649	57a7945c-9581-444c-b4a3-464cd45b6e07	/1.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:10.421551
650	57a7945c-9581-444c-b4a3-464cd45b6e07	/wp-upload.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:10.598088
651	57a7945c-9581-444c-b4a3-464cd45b6e07	/de.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:10.796271
652	57a7945c-9581-444c-b4a3-464cd45b6e07	/.dela.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:10.968499
653	57a7945c-9581-444c-b4a3-464cd45b6e07	/dropdown.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:11.138947
654	57a7945c-9581-444c-b4a3-464cd45b6e07	/ahutr.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:11.326257
655	57a7945c-9581-444c-b4a3-464cd45b6e07	/hypo.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:11.517502
656	57a7945c-9581-444c-b4a3-464cd45b6e07	/.yuf.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:11.690012
657	57a7945c-9581-444c-b4a3-464cd45b6e07	/lef.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:12.004237
658	57a7945c-9581-444c-b4a3-464cd45b6e07	/snus.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:12.184986
659	57a7945c-9581-444c-b4a3-464cd45b6e07	/wp-Blogs.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:12.370007
660	57a7945c-9581-444c-b4a3-464cd45b6e07	/multirole.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:12.551688
661	57a7945c-9581-444c-b4a3-464cd45b6e07	/aevly.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:12.74119
662	57a7945c-9581-444c-b4a3-464cd45b6e07	/un.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:12.943607
663	57a7945c-9581-444c-b4a3-464cd45b6e07	/themes4.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:13.319309
664	57a7945c-9581-444c-b4a3-464cd45b6e07	/vx.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:13.51508
665	57a7945c-9581-444c-b4a3-464cd45b6e07	/zxcs.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:13.69552
666	57a7945c-9581-444c-b4a3-464cd45b6e07	/zvz89.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:13.87685
667	57a7945c-9581-444c-b4a3-464cd45b6e07	/export.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:14.054439
668	57a7945c-9581-444c-b4a3-464cd45b6e07	/as.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:14.246358
669	57a7945c-9581-444c-b4a3-464cd45b6e07	/disagrsxr.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:14.421723
670	57a7945c-9581-444c-b4a3-464cd45b6e07	/blox.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:14.600992
671	57a7945c-9581-444c-b4a3-464cd45b6e07	/ckk.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:14.781378
672	57a7945c-9581-444c-b4a3-464cd45b6e07	/bjeni.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:14.990351
673	57a7945c-9581-444c-b4a3-464cd45b6e07	/cilng.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:15.178732
674	57a7945c-9581-444c-b4a3-464cd45b6e07	/xx.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:15.364064
675	57a7945c-9581-444c-b4a3-464cd45b6e07	/raw.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:15.55806
676	57a7945c-9581-444c-b4a3-464cd45b6e07	/class-bda.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:15.751295
677	57a7945c-9581-444c-b4a3-464cd45b6e07	/xxc.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:15.945026
678	57a7945c-9581-444c-b4a3-464cd45b6e07	/like.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:16.129132
679	57a7945c-9581-444c-b4a3-464cd45b6e07	/f222.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:16.305512
680	57a7945c-9581-444c-b4a3-464cd45b6e07	/zz.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:16.483039
681	57a7945c-9581-444c-b4a3-464cd45b6e07	/haz.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:16.661102
682	57a7945c-9581-444c-b4a3-464cd45b6e07	/class-wp-image.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:16.839747
683	57a7945c-9581-444c-b4a3-464cd45b6e07	/24name.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:17.021816
684	57a7945c-9581-444c-b4a3-464cd45b6e07	/rasse.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:17.196995
685	57a7945c-9581-444c-b4a3-464cd45b6e07	/zzx.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:17.393222
686	57a7945c-9581-444c-b4a3-464cd45b6e07	/bootstrap.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:17.567684
687	57a7945c-9581-444c-b4a3-464cd45b6e07	/class-cc.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:17.758991
688	57a7945c-9581-444c-b4a3-464cd45b6e07	/667.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:17.941238
689	57a7945c-9581-444c-b4a3-464cd45b6e07	/55l453.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:18.143747
690	57a7945c-9581-444c-b4a3-464cd45b6e07	/sd.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:18.329365
691	57a7945c-9581-444c-b4a3-464cd45b6e07	/wp-su.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:18.519993
692	57a7945c-9581-444c-b4a3-464cd45b6e07	/rea889y.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:18.705675
693	57a7945c-9581-444c-b4a3-464cd45b6e07	/wp-act.php	Unknown	Direct	0	4e6b5a41-0b62-4fb0-86ed-c03a327250b3	52.236.68.31		2026-05-10 02:29:18.896814
694	13ed2f3f-8216-4efe-9b73-f01e5ae686c9	/.env	Unknown	Direct	0	f415b2ee-912c-496f-aa13-84913b6b0aed	154.29.232.248	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	2026-05-10 02:31:04.579697
695	f6683760-c662-4146-ba63-f44a4b00ff5e	/	Unknown	Direct	0	5df8c129-3e52-4e08-952e-346b21f138cc	154.29.232.248	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	2026-05-10 02:31:05.328053
696	1702dbad-1384-4101-b040-d4c8aabfc046	/	index	Direct	0	659df8a9-26c5-4064-a388-e95b0db8191c	204.76.203.206	Mozilla/5.0	2026-05-10 02:33:39.88759
697	8995e4e9-4d4a-4024-a010-716bf1e937ef	/my-workspace	my_workspace	Direct	0	bd3754d9-2625-41f6-a762-4a7d999f0809	43.157.52.37	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-10 02:38:31.416353
698	75a7c5e9-2a66-4941-9fc6-310bf6a97610	/login	login	http://3.7.69.151/my-workspace	0	d3beec85-1460-47ee-9c42-1ca7e8acca2c	43.157.52.37	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-10 02:38:32.551129
699	71275c36-a85b-4f3b-a40e-8eff884ea94b	/	index	Direct	0	3dcbf771-979c-407a-bc03-250757bea418	204.76.203.206	Mozilla/5.0	2026-05-10 02:39:52.284742
700	003d5138-6502-476e-994e-38035c3b8761	/sitemap.xml	serve_sitemap	Direct	0	b2cb9af3-2d78-48ca-ba13-71c04f696930	37.59.204.145	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-10 02:42:43.821682
701	64e7a60a-0171-4e69-b96f-177c5c961d1c	/my-workspace	my_workspace	Direct	0	cfb0a334-ffbc-4049-97f2-9b0bc78eb54d	43.155.27.244	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-10 02:45:53.132727
702	ace3575a-acbe-401f-9934-c5e400526fb6	/login	login	https://www.gspaces.in/my-workspace	0	eaabe765-2fde-4c6b-bded-eec3cf4ac66d	43.155.27.244	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-10 02:45:54.783537
703	31c318b7-5f1f-49ba-8f9d-d18ede4cb26e	/	index	Direct	0	af26f553-da8a-4909-83cb-73d8bd50fcac	204.76.203.206	Mozilla/5.0	2026-05-10 02:49:59.86085
704	defe5b06-d2ca-470c-ada7-9f3ddcb5cb37	/signup	signup	Direct	0	48a73f52-a8da-4742-9bbc-f329f2163ca2	43.166.244.66	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-10 02:54:49.573983
705	d5644296-f36d-4d55-be24-caf26c941647	/product/21	product_detail	Direct	0	24102c4a-9baa-40a9-8437-66475a6c2940	2a03:2880:f806:40::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-10 02:56:38.943333
706	78b455e6-ed3f-420d-a94d-30e2103bff74	/	index	Direct	0	8b4204ff-1432-41aa-9420-2824f04a07fa	204.76.203.206	Mozilla/5.0	2026-05-10 03:05:04.037798
707	5f92c8a9-0ae6-4377-9550-a5591a16dca7	/forgot_password	forgot_password	Direct	0	a8c78d18-963e-4b02-b01a-ceaf3fb37e5b	43.157.46.118	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-10 03:05:06.757187
708	2b43a61b-a1e1-4962-bf2b-49dda6993661	/	index	Direct	0	ce474752-dc46-4bb9-9220-e93f6b4c996f	204.76.203.206	Mozilla/5.0	2026-05-10 03:13:28.864975
709	58756048-7bc7-4cb9-9f75-ec07d062e00a	/sitemap.xml	serve_sitemap	Direct	0	fd31656e-2d0d-40d1-a64a-411924860100	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	2026-05-10 03:15:36.36919
710	a9bc1656-d64e-47dc-a4aa-dbc6afc9c7cc	/login	login	Direct	0	ca91c60e-d974-4dce-92a3-7771f680aa29	43.153.26.165	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-10 03:16:07.88855
711	25b80d9a-972e-42cc-95bf-21e45f46407b	/	index	Direct	0	6e89e306-560c-4d0c-9b9f-67db3c6a82ba	204.76.203.206	Mozilla/5.0	2026-05-10 03:24:08.704233
712	9122c59f-6668-4817-a099-8e8065ce626e	/txets.php	Unknown	Direct	0	f5bcc5fa-3ce5-4d56-af57-6db951bac205	185.192.71.45	Go-http-client/2.0	2026-05-10 03:28:44.656882
713	c2f740d5-ded7-45c6-afc1-37ad006e2878	/wp-content/txets.php	Unknown	Direct	0	7d4333a2-c325-4dd8-9ce4-d2cb5cac8a80	185.192.71.45	Go-http-client/2.0	2026-05-10 03:28:45.229003
714	a1dd2631-5b99-49f7-b13f-b8367da03e21	/wp-admin/txets.php	Unknown	Direct	0	d268bd65-2270-43de-bf3b-3138081dd85a	185.192.71.45	Go-http-client/2.0	2026-05-10 03:28:45.657377
715	bc66a6a5-a3c6-4d6b-8522-6c23dd8d0a83	/	index	Direct	0	31449d2a-16cd-420f-a23b-7f70d8436837	204.76.203.206	Mozilla/5.0	2026-05-10 03:31:44.117808
716	d6bb76dd-78cd-47ec-9622-50e5386d4cce	/Core/Skin/Login.aspx	Unknown	Direct	0	3382ac60-6292-4699-adaf-64488f5b019c	43.129.169.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36	2026-05-10 03:35:07.206151
717	409ef56d-eb95-4db0-bfeb-fa7a123044ae	/robots.txt	Unknown	Direct	0	ac27bf20-90f7-4190-b9f2-c5667ed0c70a	174.79.247.143	Mozilla/5.0 (Macintosh; Intel Mac OS X 11_7_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.6668.29 Safari/537.36	2026-05-10 03:38:22.532771
718	8c9b87f8-b79b-4923-9d63-5146d78562ed	/	index	Direct	0	31155aad-f36f-459f-aade-d1021a9e2c43	204.76.203.206	Mozilla/5.0	2026-05-10 03:43:22.517433
719	5714e44e-b778-4b0f-9e09-960999855a94	/	index	Direct	0	635d1f74-8ff3-4af5-89c2-db83dd07f985	204.76.203.206	Mozilla/5.0	2026-05-10 03:48:11.366419
720	1f44da4d-9374-442c-9d1b-26437a6399ff	/robots.txt	Unknown	Direct	0	8bb57e3f-2f12-41d9-a238-73ccd02e7e33	2001:4ca0:108:42::24	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.134 Safari/537.36	2026-05-10 03:58:27.252289
721	359569aa-118b-4679-9d06-70e0004c657b	/	index	Direct	0	368f9367-5939-4923-a0df-c544f182d994	204.76.203.206	Mozilla/5.0	2026-05-10 03:58:34.459979
722	217c6222-86ec-4a2b-83a0-5515a80042b7	/	index	http://www.gspaces.in/	0	24a4f4b0-cb2b-48b1-91cb-7a3d421c5aba	194.132.63.30	Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.3	2026-05-10 04:04:04.759245
723	bd6f56e8-9b8a-4eb3-a3b2-e24a6d2cc3ec	/sitemap.xml	serve_sitemap	Direct	0	fdb2e870-db05-4a7a-a77b-ea7f68ac4ac3	37.59.204.145	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-10 04:06:19.402955
724	17ef1f37-9016-44d4-bc22-246518b11dfc	/	index	Direct	0	53f5c414-c4f8-4ec9-b91c-a7c46e5b8898	204.76.203.206	Mozilla/5.0	2026-05-10 04:10:22.331149
725	d47dfb14-bec1-44dc-bc56-36da6b570d46	/.env	Unknown	Direct	0	57ba4739-234e-477e-a3a5-7873a0079d17	82.21.244.235	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	2026-05-10 04:13:01.680729
726	38b90a8a-2ee0-433b-bcb0-00e8dc49cca3	/	Unknown	Direct	0	8dc7eccc-9c9b-4a86-aa52-ab847149e0a5	82.21.244.235	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	2026-05-10 04:13:02.99933
727	2f7c03b2-50ff-4a61-a270-97c0d13abe85	/	index	http://www.gspaces.in	0	420f3b47-21fb-4b97-be03-f68373a6c286	175.178.110.121	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-10 04:14:40.960042
728	617bc9ea-2dfc-43ac-ab75-40f9301677a6	/	index	Direct	0	e62f9f35-9f3f-401b-8580-59ba2d031e49	204.76.203.206	Mozilla/5.0	2026-05-10 04:22:50.433933
729	01bad875-f33a-43b5-8ff6-3211f6dd881e	/robots.txt	Unknown	Direct	0	ba17e527-faf0-48b5-8dbe-340bd3e0a667	216.73.216.13	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)	2026-05-10 04:31:19.021756
730	2b4f9d4d-27b1-4750-a688-a2833fd4349b	/	index	Direct	0	13f50aae-5612-4d90-af1e-ec8a7a6dcccd	204.76.203.206	Mozilla/5.0	2026-05-10 04:32:18.83696
731	226ee813-d6b4-45a0-99a5-ec892be142c2	/	index	http://gspaces.in	0	5f9e4ef0-308d-4af6-9755-6207d99dcfa7	20.207.201.147	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36	2026-05-10 04:38:43.618106
732	278c34a0-cf8e-45aa-828c-0739fb5c5fdf	/	index	Direct	0	dcf5fd38-415c-4e69-9240-5ff41885dc8f	204.76.203.206	Mozilla/5.0	2026-05-10 04:42:02.63814
733	a28c82b2-7406-4199-8d44-05f0b950b9b3	/	index	Direct	0	90d2d20a-b85b-4064-a61a-d269c3f6d40b	43.163.206.70	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-10 04:47:40.599086
734	a73e20ec-b0e9-4b76-aac9-995b2699f07f	/	index	Direct	0	10608683-e4b9-4289-b7b4-5b7308130217	204.76.203.206	Mozilla/5.0	2026-05-10 04:51:57.629268
735	2d051033-70d6-4903-b7f3-2d93e19d7dc1	/login	login	Direct	0	ef7b94a2-6372-4141-8d36-5ac8c2b1eb4b	93.123.109.222	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36	2026-05-10 04:52:20.473344
736	3bfca07f-be86-4823-95a1-b63b9ec92ed4	/wp-login.php	Unknown	Direct	0	374deea2-50f9-4c50-bb23-bd04d57acb78	45.8.19.91	Mozilla/5.0	2026-05-10 04:54:47.740864
737	13bfc2c6-550e-4d5e-ab47-b14ad41fb43e	/	index	Direct	0	7d390d78-1a0d-48d6-bbeb-aa8b8674f7d7	204.76.203.206	Mozilla/5.0	2026-05-10 04:57:32.675324
738	ed7fba3d-2c2e-40a1-993e-dd1382f86e57	/	index	Direct	0	5767d3ec-02aa-4609-8ed9-9fbdb4a36e29	204.76.203.206	Mozilla/5.0	2026-05-10 05:06:17.635117
739	4c7ba489-256c-40af-9b50-3641a96fe144	/login	login	Direct	0	6fe95d7e-9b4e-4e8e-bbd5-38263d344469	18.214.206.100	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amzn-SearchBot/0.1) Chrome/119.0.6045.214 Safari/537.36	2026-05-10 05:12:18.629425
740	dc993eac-f8df-4809-b89b-08cb70fc6ea0	/sitemap.xml	serve_sitemap	Direct	0	72151859-4349-43c3-82b8-6e63881c591f	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	2026-05-10 05:12:36.608862
741	7904bd45-6bad-4c65-868d-30141c6588ad	/	index	Direct	0	43a72241-0d60-4aa1-acf5-0d9ab614e5e0	204.76.203.206	Mozilla/5.0	2026-05-10 05:17:52.797017
742	8064f700-8e6b-4603-a61b-3937aff98bc9	/	index	Direct	0	06310f65-b3e8-40a5-a3a7-fea9ce6fe78c	204.76.203.206	Mozilla/5.0	2026-05-10 05:24:15.082213
743	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/	index	Direct	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:27:58.634513
744	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/profile	profile	https://gspaces.in/	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:28:05.186884
745	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/login	login	https://gspaces.in/	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:28:05.662109
746	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/google_signin	google_signin	https://gspaces.in/login?next=%2Fprofile	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:28:12.837418
747	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/	index	https://gspaces.in/login?next=%2Fprofile	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:28:13.342819
748	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/orders	admin_orders	https://gspaces.in/	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:28:22.723481
749	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/orders	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:28:30.526151
750	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:28:37.882338
751	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=1&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:29:09.051948
752	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=1&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:29:40.173021
753	50cb4fc7-2e8d-46b4-a9da-f718af47c900	/	index	http://gspaces.in	0	a436f6ed-b07b-46c8-bf3e-f913363a0402	170.106.37.134	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	2026-05-10 05:30:11.352604
754	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=1&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:30:11.650881
755	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=1&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:30:14.692033
756	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=90&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:30:45.923279
757	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=90&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:31:16.891349
758	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=90&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:31:48.824037
759	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=90&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:32:19.779249
760	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=90&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:32:50.763427
761	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=90&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:33:21.854944
829	abccd373-b9ed-4917-bcb7-64bceb7dfe17	/lib/phpunit/phpunit/Util/PHP/eval-stdin.php	Unknown	Direct	0	18a82cc5-73b5-4003-bbf6-d42cae5a9bb4	146.190.89.51	libredtail-http	2026-05-10 07:23:37.59841
762	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=90&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:33:52.763027
763	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=90&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:34:24.13242
764	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=90&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:34:55.850396
765	62e61e0c-44a5-4dd0-8f68-997b1a69a4ae	/sitemap.xml	serve_sitemap	Direct	0	87c542f7-21cc-4f4d-833e-3280ada837b4	94.23.188.192	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-10 05:36:06.394733
766	9bef71dd-1b3e-4c47-80c9-93d4bea4e409	/	index	Direct	0	ac054765-aefc-4cca-ac46-ea632a12ef49	204.76.203.206	Mozilla/5.0	2026-05-10 05:39:35.350954
767	bb52e0cd-9edd-4a9b-a530-f3059ddcb99c	/robots.txt	Unknown	Direct	0	f674ced9-dcaa-41ee-a37f-7f50daa1de62	47.128.53.184	Mozilla/5.0 (Linux; Android 5.0) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; Bytespider; spider-feedback@bytedance.com)	2026-05-10 05:43:30.226307
768	4cbd5ff1-4833-46ec-89bb-77da32516c3e	/admin/visitors	visitor_tracking.admin_visitors	https://gspaces.in/admin/visitors?date_filter=90&device=all&country=all	0	27ca364f-d4b5-4895-9517-f6db7249cc9a	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	2026-05-10 05:45:15.84318
769	b9b5e2e3-e426-4857-bbf7-7d25a03ccbbe	/login	login	Direct	0	ebd97636-3588-4a7a-931a-cadf816fa55f	66.132.172.110	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	2026-05-10 05:46:37.61956
770	36cd12bc-4424-4343-99ee-e0395fa153f0	/favicon.ico	Unknown	Direct	0	b91e4e66-468c-47db-bbbe-582280faf4ef	66.132.172.110	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	2026-05-10 05:46:47.34228
771	6c4436f3-61ec-47ff-81d1-5137827e5f0a	/rz22vmrxvcfswmfmc	Unknown	Direct	0	7e55c2d7-be9c-46cf-acde-035d39547564	66.132.172.110	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	2026-05-10 05:46:54.280421
772	7826fe3e-c804-457d-b9f2-cdb2cd826864	/	index	Direct	0	45dcdb73-3119-48df-a6c5-a8f632d10072	66.132.195.108	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	2026-05-10 05:47:59.102469
773	aa16459a-9d13-49e8-81ff-28d382472644	/favicon.ico	Unknown	Direct	0	6b7c457d-bd15-4375-b928-56ecfa96cb09	66.132.195.108	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	2026-05-10 05:48:06.612287
774	1eb12c46-b94d-49cc-8791-f47a44e09d8c	/	index	Direct	0	0d252c29-5735-4895-88dd-5943a22b7ce6	66.132.195.108	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	2026-05-10 05:48:31.419357
775	8e4bbfb1-3348-418c-adc2-804b0757868c	/security.txt	Unknown	Direct	0	f11bfc9a-0bc6-484d-870b-54353085c346	66.132.195.108	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	2026-05-10 05:48:43.210069
776	dedb828f-98d8-4809-9084-0de1a0df8a4e	/product/22	product_detail	Direct	0	f417e0ff-f69f-4528-b214-7b69b7b57a8a	2a03:2880:f806:5::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	2026-05-10 05:48:45.110492
777	ea4a52c7-fb9a-46d8-8403-71d9ceb32739	/	index	Direct	0	b433108d-638b-4eca-9131-2e9b22f674ba	204.76.203.206	Mozilla/5.0	2026-05-10 05:51:04.841224
778	183b5333-9868-48e9-b9ca-8eace104caeb	/.env	Unknown	Direct	0	2938aafd-a222-482d-9679-8465e0bf0112	82.27.247.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	2026-05-10 05:56:59.056807
779	c9972575-bdca-4cbe-81e7-b964c2938c07	/	Unknown	Direct	0	cc05fb36-e092-441a-809d-7058b838897e	82.27.247.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	2026-05-10 05:56:59.448645
780	bb077754-8091-49a2-8962-0d0b98cfa4a3	/	index	Direct	0	b1be8cb4-5347-44b9-950c-ee2094dd51a9	204.76.203.206	Mozilla/5.0	2026-05-10 05:57:43.781093
781	bf235532-102d-43f5-91f1-5f43f0488801	/	index	Direct	0	b5a63b36-7953-459c-9fa2-7f03c8d6198b	178.18.247.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15	2026-05-10 05:58:45.706714
782	7f1745da-a0ba-44e2-85fe-54532e8682af	/media/system/js/core.js	Unknown	http://gspaces.in/media/system/js/core.js	0	2bf8fd79-58d2-4cf5-b320-a703cc712675	34.73.31.200	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36	2026-05-10 06:11:24.218908
783	dd45b35c-70ef-4143-8134-88892b4dcc92	/wp-includes/js/jquery/jquery.js	Unknown	http://gspaces.in/wp-includes/js/jquery/jquery.js	0	3b739714-4a82-4179-8fa4-0d50ced71fbf	34.73.31.200	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36	2026-05-10 06:11:26.479489
784	4ac1098b-6edb-4b22-b27d-342672e68c73	/	index	Direct	0	b18dc733-440d-4684-87a2-ef3c531d13d0	204.76.203.206	Mozilla/5.0	2026-05-10 06:16:49.12869
785	7f3ebcad-7d58-42a2-a737-f98a4a71fb1b	/robots.txt	Unknown	Direct	0	12860bf2-661a-4cbc-80eb-3b63d0d677c2	110.249.201.151	Mozilla/5.0 (Linux; Android 5.0) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; Bytespider; https://zhanzhang.toutiao.com/)	2026-05-10 06:17:13.654813
786	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	/	index	https://gspaces.in/admin/leads	0	466a7261-91fb-462d-a66a-3ef84243c341	2406:b400:b4:b6a:49a0:f609:780d:1ad6	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 06:21:27.31627
787	623c74ea-ad7d-4ab3-bc4f-840451002c68	/	index	Direct	0	656bd28e-ce94-47c1-8af1-82f48b85395e	2406:b400:b4:b6a:49a0:f609:780d:1ad6	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 06:21:35.377742
788	3e49f9f7-0174-4a54-b3b9-62e27948acff	/	index	https://gspaces.in/admin/leads	0	113fdd6d-74f0-4d70-8d7d-a491464706ed	2406:b400:b4:b6a:49a0:f609:780d:1ad6	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 06:25:05.570552
789	3e49f9f7-0174-4a54-b3b9-62e27948acff	/	index	Direct	0	113fdd6d-74f0-4d70-8d7d-a491464706ed	2406:b400:b4:b6a:49a0:f609:780d:1ad6	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 06:25:08.961858
790	3e49f9f7-0174-4a54-b3b9-62e27948acff	/	index	Direct	0	113fdd6d-74f0-4d70-8d7d-a491464706ed	2406:b400:b4:b6a:49a0:f609:780d:1ad6	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 06:25:51.751104
791	1f9f68b7-c59b-464a-9501-22b843a88089	/	index	Direct	0	71723c25-4ccc-4989-a11e-b2fa20038b55	204.76.203.206	Mozilla/5.0	2026-05-10 06:26:06.849388
792	3e49f9f7-0174-4a54-b3b9-62e27948acff	/profile	profile	https://gspaces.in/	0	113fdd6d-74f0-4d70-8d7d-a491464706ed	2406:b400:b4:b6a:49a0:f609:780d:1ad6	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 06:26:23.905474
793	3e49f9f7-0174-4a54-b3b9-62e27948acff	/login	login	https://gspaces.in/	0	113fdd6d-74f0-4d70-8d7d-a491464706ed	2406:b400:b4:b6a:49a0:f609:780d:1ad6	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-10 06:26:24.076309
794	24819296-32f9-4e0f-96ca-5fe46a092715	/my-workspace	my_workspace	Direct	0	07627a8a-4f21-4340-8ef1-6880c4e340b3	54.209.139.3	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amzn-SearchBot/0.1) Chrome/119.0.6045.214 Safari/537.36	2026-05-10 06:43:58.569599
795	e1a2f69b-9ee3-42b7-ba86-6bdcfe3cd4b3	/login	login	Direct	0	423ac0b5-68bb-4bac-8161-9db2a3e55277	54.209.139.3	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amzn-SearchBot/0.1) Chrome/119.0.6045.214 Safari/537.36	2026-05-10 06:43:59.233064
796	100e1374-2468-438b-a767-ecc117c5c484	/terms	terms	Direct	0	7cb23a57-25c3-475f-b377-abf875e76325	5.39.1.227	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-10 06:44:49.643751
797	eaaa8e75-a693-4e11-9ebf-7663ca6ce909	/	index	Direct	0	a94e8230-38c4-46fb-bc21-0417a522b830	204.76.203.206	Mozilla/5.0	2026-05-10 06:47:09.627192
798	dc102c54-727c-412b-8811-aad8d51f55d6	/Core/Skin/Login.aspx	Unknown	Direct	0	c13f7cf1-7f76-4ece-835c-b7173c7215ad	43.129.169.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36	2026-05-10 06:51:00.95476
799	480da258-1d5b-4b80-8f62-c0feec065532	/	index	Direct	0	edab6967-f98b-48c0-bdbd-95464a15fc15	127.0.0.1	python-requests/2.25.1	2026-05-10 06:51:12.394767
800	24179934-a9e4-42a9-9155-028e57a45bf1	/products	products	Direct	0	d15e2904-cd91-46ce-9e5c-9a3d9df92038	127.0.0.1	python-requests/2.25.1	2026-05-10 06:51:12.461904
801	720736fc-c9e1-40ad-921a-31d43145a8fe	/about	about	Direct	0	e270141c-f5ae-4384-a471-e4e7bd654305	127.0.0.1	python-requests/2.25.1	2026-05-10 06:51:12.545482
802	09f94c45-0417-4613-9bfd-ec47ea33b28b	/contact	contact	Direct	0	8e3f6e7c-507d-45a4-9c81-1461cbf15369	127.0.0.1	python-requests/2.25.1	2026-05-10 06:51:12.58241
803	4b7530d1-bd92-4234-a8f9-0f7f3b41a737	/services	Unknown	Direct	0	049c89be-3e18-4de5-af57-db90c5e76c2c	127.0.0.1	python-requests/2.25.1	2026-05-10 06:51:12.625101
804	a1865372-4bb8-4668-b0be-f5b9fbc79f5d	/blogs	blogs	Direct	0	6474f511-6dbc-4066-bfa5-dd14a8ccbb3b	127.0.0.1	python-requests/2.25.1	2026-05-10 06:51:12.65666
805	1d569c19-cb10-44b5-9078-87cbccaf1f80	/login	login	Direct	0	3912da9c-8579-4ff0-adc3-05545714dc07	127.0.0.1	python-requests/2.25.1	2026-05-10 06:51:12.716958
806	92a86a49-610b-43e3-b000-5d2304e0ee47	/signup	signup	Direct	0	c68e9ff1-196d-4c06-bb19-a3cca17508bb	127.0.0.1	python-requests/2.25.1	2026-05-10 06:51:12.756694
807	a73ab2ac-e961-4198-99e7-af2b7888223e	/	index	Direct	0	808e58eb-24b7-4a98-a6b3-4f3b0f3cba6b	204.76.203.206	Mozilla/5.0	2026-05-10 06:52:33.718075
808	8f24fe82-4cc3-4674-a151-1569676a3d5a	/phpmyadmin/index.php	Unknown	Direct	0	1df9510a-7a00-4a3d-99ec-c70a5005ab7b	119.45.228.157	Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3464.0 Safari/537.36	2026-05-10 07:00:10.612817
809	06eb2077-0fe9-4a10-bba6-7f3fb661e130	/pmd/index.php	Unknown	Direct	0	3a4298b5-168f-4f6c-8ff6-ea5dc880e238	119.45.228.157	Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3464.0 Safari/537.36	2026-05-10 07:00:10.779332
810	958e2b09-a27f-4c58-8517-d70354bf9057	/phpmyadmin4.8.5/index.php	Unknown	Direct	0	0a0dbebe-8eea-4216-827c-4fe677dad11e	119.45.228.157	Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3464.0 Safari/537.36	2026-05-10 07:00:10.94971
811	c734af23-5e24-4865-b7fd-9da5d0d46122	/	index	Direct	0	1e2fdb9c-a869-4a4d-9bf2-ba1820bad23b	204.76.203.206	Mozilla/5.0	2026-05-10 07:02:33.718195
812	a54b592f-b994-43c9-8f3a-81d4736ba230	/sitemap.xml	serve_sitemap	Direct	0	c781e805-155b-46b9-a59e-93bbb7ce8920	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	2026-05-10 07:07:14.130509
813	795cbeb0-c45a-42cd-a627-7269dbaeea77	/	index	Direct	0	5e1ae19c-33b8-4b35-aa13-20edbf4d37f8	204.76.203.206	Mozilla/5.0	2026-05-10 07:11:31.269711
814	7aff0c5b-7e38-44dc-945f-4e24c5fe4e74	/	index	Direct	0	e171079c-d936-4f22-876f-b12617ac05c3	204.76.203.206	Mozilla/5.0	2026-05-10 07:18:19.649187
815	cdb17911-efb4-41e8-9950-e28745402b5c	/sitemap.xml	serve_sitemap	Direct	0	d4329295-8f41-42fa-a981-0f810800fa55	37.59.204.149	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	2026-05-10 07:22:11.047286
816	36afe508-1330-43b3-86f9-295edc15e616	/hello.world	Unknown	Direct	0	bc983b65-8f27-4f50-98cd-a2536b4738d3	146.190.89.51	libredtail-http	2026-05-10 07:23:30.329645
817	dfb252d5-8f3f-4f07-9fe4-3c3e59b4fbdd	/	Unknown	Direct	0	e384651d-f6b7-42fd-a210-afff3c8d1107	146.190.89.51	libredtail-http	2026-05-10 07:23:31.102978
818	4f7dbc82-6817-4de3-8887-472f91504cc7	/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	a5cf04cf-a744-4a29-b069-65654170adb2	146.190.89.51	libredtail-http	2026-05-10 07:23:31.539885
819	198a2747-e7b3-4e62-91f8-74a72f683b1f	/vendor/phpunit/phpunit/Util/PHP/eval-stdin.php	Unknown	Direct	0	19b33f66-9a3c-4e39-b96c-2825ae8d5ee4	146.190.89.51	libredtail-http	2026-05-10 07:23:32.007826
820	d0c51928-b908-480a-b353-201ab41a9878	/vendor/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	3034eb22-640f-41af-8dd4-3ccaf9f66109	146.190.89.51	libredtail-http	2026-05-10 07:23:32.47297
821	c8a8706f-6561-49a1-9ed3-939a4465e36c	/vendor/phpunit/Util/PHP/eval-stdin.php	Unknown	Direct	0	eced392f-fc9b-48e0-a52d-97f9f1241ea4	146.190.89.51	libredtail-http	2026-05-10 07:23:33.10437
822	2158191e-1048-48f5-ad81-0fdb8dc73e0b	/vendor/phpunit/phpunit/LICENSE/eval-stdin.php	Unknown	Direct	0	c1dbfb81-806a-4bd8-9cf0-70c257f5f1bf	146.190.89.51	libredtail-http	2026-05-10 07:23:33.602681
823	a2dfa168-d3d7-4278-8176-33c5d5e36b1e	/vendor/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	3063e6de-fe57-4b4d-963d-82084fa9571a	146.190.89.51	libredtail-http	2026-05-10 07:23:34.057381
824	fd2b8a88-127a-4423-b3fb-e1f65009ac90	/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	7cc33727-43a8-47c9-9026-0286a36c48f7	146.190.89.51	libredtail-http	2026-05-10 07:23:34.55359
825	2d33503f-3976-47d8-a697-61ff17125f73	/phpunit/phpunit/Util/PHP/eval-stdin.php	Unknown	Direct	0	ef9f774c-4017-439c-9809-170f1603b0d4	146.190.89.51	libredtail-http	2026-05-10 07:23:35.233895
826	062def44-7866-405d-a89b-c29ce2239315	/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	c39146bb-c968-4580-9801-4b3324b4c934	146.190.89.51	libredtail-http	2026-05-10 07:23:35.881393
827	3be5069d-d73c-4e87-abcf-0e6b3d99491b	/phpunit/Util/PHP/eval-stdin.php	Unknown	Direct	0	1b0b33ce-190f-438b-864e-e8308030cfb2	146.190.89.51	libredtail-http	2026-05-10 07:23:36.624115
828	c96e180c-a049-4f62-b8e6-6ac6af8d923b	/lib/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	55e5e03a-678e-43ab-b2d8-c696592ddad5	146.190.89.51	libredtail-http	2026-05-10 07:23:37.094242
830	4d9af1dd-d491-478e-adfd-b37cb1eda4fd	/lib/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	89640572-08df-4b52-985e-a8a6cc9badc3	146.190.89.51	libredtail-http	2026-05-10 07:23:38.078747
831	fc0db638-46cc-4831-9220-b0510d1399d5	/lib/phpunit/Util/PHP/eval-stdin.php	Unknown	Direct	0	8ffb8a9f-9971-4ea9-b386-ddfd4c1e550b	146.190.89.51	libredtail-http	2026-05-10 07:23:38.782319
832	251154d1-42a5-4988-bd9a-3e0ee5622074	/lib/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	62f35bab-0f94-4071-924d-abd1902b0fa7	146.190.89.51	libredtail-http	2026-05-10 07:23:39.159752
833	cb44d120-a260-4799-bf0f-89b6d60acdf4	/laravel/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	58dc73f0-0d77-4b8b-8303-3c1ed5b99932	146.190.89.51	libredtail-http	2026-05-10 07:23:39.671391
834	c6b98f4b-ec7b-48f0-b375-ae5916c8870c	/www/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	cbb5a799-2d92-4c18-be81-1f1908e098af	146.190.89.51	libredtail-http	2026-05-10 07:23:40.130549
835	0279e89f-a3e4-41a5-993b-76460541e26a	/ws/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	d47ce86f-fb1f-4202-90ce-6791c34ca5c4	146.190.89.51	libredtail-http	2026-05-10 07:23:40.68594
836	7821fdfd-e118-41f7-961f-022065f1cdd1	/yii/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	03ace68d-f0de-4309-89a2-32fc8791d086	146.190.89.51	libredtail-http	2026-05-10 07:23:41.030069
837	4a47a64f-411b-41a2-9929-b1aa57aa966f	/zend/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	3d009b7f-3e54-4e4f-9054-03adba04f5a7	146.190.89.51	libredtail-http	2026-05-10 07:23:41.50827
838	52f2fdef-7211-4b7c-b1ee-4529bbab496d	/ws/ec/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	ec6befcc-db8f-4b08-ba5d-15da1e656a78	146.190.89.51	libredtail-http	2026-05-10 07:23:41.941168
839	bd9551be-d7ad-40ea-bcad-38454b293c85	/V2/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	54a080b6-6d54-4205-84d7-d00b2a897f40	146.190.89.51	libredtail-http	2026-05-10 07:23:42.582177
840	fec270f9-8c8e-407e-94c1-e1595768ce91	/tests/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	cccf9906-56d5-48f7-bf56-9844f5fba4ef	146.190.89.51	libredtail-http	2026-05-10 07:23:42.955848
841	45de9d22-fd9a-4551-90d7-6cc00f455297	/test/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	5781b28e-5208-4120-b906-715ccc06f432	146.190.89.51	libredtail-http	2026-05-10 07:23:43.433672
842	847c49ea-ba9d-4d9e-be1b-351f37ff04c5	/testing/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	e82a5f37-9478-4624-834b-9030ebf0e6c2	146.190.89.51	libredtail-http	2026-05-10 07:23:43.849538
843	972716b4-74db-4187-8c89-aec26065866f	/demo/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	112b4891-52c1-4e34-870e-d357bbab2faf	146.190.89.51	libredtail-http	2026-05-10 07:23:44.60318
844	5b85cccd-a6e0-48fc-accf-dcbb96ac04b9	/cms/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	a6dea1c8-98cb-4acc-b1ed-02653c54a970	146.190.89.51	libredtail-http	2026-05-10 07:23:44.918161
845	9ecc63b6-683b-4560-914f-49c86205f9d3	/crm/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	b600dbbf-cf7f-404c-9dee-a760a7f99e4d	146.190.89.51	libredtail-http	2026-05-10 07:23:45.275315
846	44c15d07-980b-42c6-bc8c-7bf4b934b2a5	/admin/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	042759a6-e968-4f5e-83f8-9406ba689a37	146.190.89.51	libredtail-http	2026-05-10 07:23:45.614999
847	5dc63aab-2da7-4d13-b612-dc03d7934c39	/backup/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	11b7c84e-972e-469f-b407-ac6a36ddaa58	146.190.89.51	libredtail-http	2026-05-10 07:23:46.082706
848	d0c78cda-73a0-4081-a8c1-b0cb03892af8	/blog/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	20c38a24-756f-425e-912f-2780372d376a	146.190.89.51	libredtail-http	2026-05-10 07:23:46.642572
849	b78bf473-94f3-4b39-b688-fc9fcce81094	/workspace/drupal/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	f2102294-e7c0-45eb-8165-70e405e0e5fe	146.190.89.51	libredtail-http	2026-05-10 07:23:47.309317
850	1e60492d-1ef8-434a-9d6a-0db84e54b27f	/panel/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	22cd5940-d6e8-4954-9b5e-1af828dce04f	146.190.89.51	libredtail-http	2026-05-10 07:23:47.91696
851	60183897-89e6-4272-b58f-7c04d2663bea	/public/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	28e1ae85-1289-49fb-88e6-bfccd9a39fbe	146.190.89.51	libredtail-http	2026-05-10 07:23:48.47214
852	b92db2d7-9b29-4031-8772-cfdcbbf9e048	/apps/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	4ca1b918-9779-40a2-af04-7b27410db594	146.190.89.51	libredtail-http	2026-05-10 07:23:48.966249
853	c19d6801-d649-40ea-b714-1340f83e445a	/app/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	Unknown	Direct	0	db66c8bf-a9ce-4888-b78c-8039a632f789	146.190.89.51	libredtail-http	2026-05-10 07:23:49.547184
854	aecd52d1-972e-4c89-aa88-3fd8a5f44536	/index.php	Unknown	Direct	0	1bf8a2b0-9a5b-4eb9-a0ee-e53d3a907c1a	146.190.89.51	libredtail-http	2026-05-10 07:23:50.04378
855	ed293d04-c906-4734-8bfe-fb732251c161	/public/index.php	Unknown	Direct	0	73ffb374-a41e-4172-8fb0-144c911e8bf1	146.190.89.51	libredtail-http	2026-05-10 07:23:50.62616
856	632dde81-c845-4c61-9a9c-e75dc0ae7093	/index.php	Unknown	Direct	0	de9b501d-dc74-495b-8301-b2d91680dcfc	146.190.89.51	libredtail-http	2026-05-10 07:23:51.069749
857	e92c7664-4d78-4b43-9cd5-dcb006a17a31	/index.php	Unknown	Direct	0	75a8d6d1-2224-47d1-99f2-c395a516a261	146.190.89.51	libredtail-http	2026-05-10 07:23:51.493286
858	d415f4ec-b4c8-4aa2-866c-cc7a25826a5e	/containers/json	Unknown	Direct	0	44496386-0aa0-4ed2-94ed-e03834904482	146.190.89.51	libredtail-http	2026-05-10 07:23:51.845889
\.


--
-- Data for Name: pricing_rules; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.pricing_rules (id, item_category, item_type, base_price, price_per_unit, description, updated_at) FROM stdin;
1	table	iron_legs_4x2	12000.00	0.00	Iron legs table 4x2	2026-05-02 19:01:58.506801
2	table	iron_legs_5x2	18000.00	0.00	Iron legs table 5x2	2026-05-02 19:01:58.506801
3	table	wooden_legs_4x2	15000.00	0.00	Wooden legs U-shaped table 4x2	2026-05-02 19:01:58.506801
4	table	storage_addon	8000.00	0.00	Storage addon for any table	2026-05-02 19:01:58.506801
5	chair	basic	6000.00	0.00	Basic chair	2026-05-02 19:01:58.506801
6	chair	basic_headrest	8000.00	0.00	Basic chair with headrest	2026-05-02 19:01:58.506801
7	chair	medium	15000.00	0.00	Medium range chair (10k-20k avg)	2026-05-02 19:01:58.506801
8	chair	high	25000.00	0.00	High range chair (20k+ avg)	2026-05-02 19:01:58.506801
9	plants	mini	400.00	400.00	Mini plant with pot	2026-05-02 19:01:58.506801
10	plants	big	1000.00	1000.00	Big plant with pot	2026-05-02 19:01:58.506801
11	artefacts	mini	700.00	700.00	Mini artefact	2026-05-02 19:01:58.506801
12	frames	mini	800.00	800.00	Mini frame	2026-05-02 19:01:58.506801
13	frames	medium	1200.00	1200.00	Medium frame	2026-05-02 19:01:58.506801
14	frames	large	2000.00	2000.00	Large frame	2026-05-02 19:01:58.506801
15	lamp	basic	1000.00	0.00	Basic table lamp	2026-05-02 19:01:58.506801
16	lamp	medium	2000.00	0.00	Medium table lamp	2026-05-02 19:01:58.506801
17	lamp	high	3000.00	0.00	High-end table lamp	2026-05-02 19:01:58.506801
18	accessory	multisocket	1200.00	0.00	Multisocket	2026-05-02 19:01:58.506801
19	accessory	cable_organiser	1200.00	0.00	Cable organiser	2026-05-02 19:01:58.506801
20	accessory	deskmat	1000.00	0.00	Desk mat	2026-05-02 19:01:58.506801
21	accessory	floor_mat	0.00	500.00	Floor mat (per sq ft)	2026-05-02 19:01:58.506801
22	accessory	profile_light	0.00	300.00	Profile light (per ft)	2026-05-02 19:01:58.506801
23	accessory	clock	1000.00	0.00	Wall clock	2026-05-02 19:01:58.506801
24	accessory	pegboard	1000.00	1000.00	Pegboard (per sq ft)	2026-05-02 19:01:58.506801
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
133	21	img/Products/basic-big-plant.png	4ft height plant with gray pot	2026-05-01 07:53:52.213127
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.products (id, name, description, category, price, rating, image_url, created_by, detailed_description, deal_percent, review_count, category_id, original_price, discount_percent, discounted_price) FROM stdin;
25	Individual Space (Get What You See)	C-402	Couple	60000.0	5.0	img/Products/C-402.png	srichityala501@gmail.com	\N	0	0	\N	\N	0.00	\N
24	Dual Minds (Get What You See)	C-401	Couple	68000.0	5.0	img/Products/C-401.png	srichityala501@gmail.com	\N	0	0	\N	\N	0.00	\N
17	Elegant Corner (Get What You See)	L-601	Elegant	60000.0	5.0	img/Products/17/17.jpg	srichityala501@gmail.com	\N	0	0	\N	\N	0.00	\N
23	Green Asset (Get What You See)	G-501	Greenery	60000.0	5.0	img/Products/23/23.jpg	srichityala501@gmail.com	\N	0	0	\N	\N	0.00	\N
21	Magic Wood (Get What You See)	M-104	Basic	27000.0	4.0	img/Products/21/21.jpg	srichityala501@gmail.com	\N	0	0	\N	\N	0.00	\N
7	Base Green (Get What You See)	S-201	Storage	48000	5.0	img/Products/7/7.jpg	sri@gmail.com	Nature	0	0	\N	\N	0.00	\N
10	Bright Space (Get What You See)	S-204	Storage	42000	5.0	img/Products/10/10.jpg	sri@gmail.com	Storage	0	1	\N	\N	0.00	\N
31	Warm Wood	M-103	Basic	25000	5.0	img/Products/31/31.jpg	srichityala501@gmail.com	\N	0	0	\N	\N	0.00	\N
26	Dark Magic (Get What You See)	L-601	Luxury	90000.0	5.0	img/Products/26/26.jpg	srichityala501@gmail.com	\N	0	0	\N	\N	0.00	\N
27	Rafter Studio Setup (Get What You See)	S-701	Studio	150000.0	5.0	img/Products/27/27.jpg	srichityala501@gmail.com	\N	0	0	\N	\N	0.00	\N
22	Soft Sky (Get What You See)	E-303	Elegant	48000.0	5.0	img/Products/22/22.jpg	srichityala501@gmail.com	\N	0	0	\N	\N	0.00	\N
29	Beige Minds (Get What You See)	S-206	Storage	38000.0	5.0	img/Products/29/29.jpg	srichityala501@gmail.com	\N	0	0	\N	\N	0.00	\N
28	Scandi Minimal (Get What You See)	M-102	Basic	25000.0	5.0	img/Products/28/28.jpg	srichityala501@gmail.com	\N	0	0	\N	\N	0.00	\N
30	Semi Wood (Get What You See)	M-101	Basic	1	5.0	img/Products/30/30.jpg	srichityala501@gmail.com	\N	0	0	\N	\N	0.00	\N
\.


--
-- Data for Name: referral_coupons; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.referral_coupons (id, user_id, coupon_code, discount_percentage, referral_bonus_percentage, times_used, total_referral_earnings, is_active, created_at, expires_at, discount_type, discount_amount, referrer_bonus_type, referrer_bonus_amount, min_order_amount, max_discount_amount, first_order_only, usage_limit, per_user_limit, description) FROM stdin;
68	34	SREEKA34	5.00	5.00	0	0.00	t	2026-04-23 14:09:30.695614	2027-04-23 14:09:30.695618	percentage	0.00	percentage	0.00	0.00	\N	f	\N	1	\N
70	36	HOME36	5.00	5.00	0	0.00	t	2026-04-30 13:08:17.13043	2027-04-30 13:08:17.130434	percentage	0.00	percentage	0.00	0.00	\N	f	\N	1	\N
4	15	SREEKA15	10.00	10.00	0	0.00	t	2026-04-16 21:36:04.702662	2026-05-16 21:36:04.702662	fixed	1000.00	fixed	2000.00	0.00	\N	f	\N	1	Default referral coupon - ₹1000 off for friend, ₹1000 bonus for referrer
69	35	SREEKA35	5.00	5.00	0	0.00	t	2026-04-28 20:19:24.454227	2027-04-28 20:19:24.45423	percentage	0.00	percentage	0.00	0.00	\N	f	\N	1	\N
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
-- Data for Name: room_visualizations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.room_visualizations (id, user_id, product_id, room_image_url, result_image_url, created_at) FROM stdin;
1	14	7	uploads/visualizations/room_14_20260429_091446.jpg	uploads/visualizations/result_14_20260429_091446.jpg	2026-04-29 09:14:46.118034
2	14	7	uploads/visualizations/room_14_20260429_104618.jpg	uploads/visualizations/result_14_20260429_104618.png	2026-04-29 10:46:18.17417
3	14	7	uploads/visualizations/room_14_20260429_105106.jpg	uploads/visualizations/result_14_20260429_105106.png	2026-04-29 10:51:06.782415
4	14	7	uploads/visualizations/room_14_20260429_105410.jpg	uploads/visualizations/result_14_20260429_105410.png	2026-04-29 10:54:10.324101
5	14	7	uploads/visualizations/room_14_20260429_110611.jpg	uploads/visualizations/result_14_20260429_110611.png	2026-04-29 11:06:11.507567
\.


--
-- Data for Name: system_health_logs; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.system_health_logs (id, check_type, status, error_message, response_time, endpoint, details, created_at) FROM stdin;
\.


--
-- Data for Name: user_workspace_items; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.user_workspace_items (id, user_id, name, image_data, category, width, height, position_x, position_y, rotation_angle, scale_factor, z_index, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.users (id, name, email, password, address, phone, profile_photo, address_line_2, city, state, pincode, country, landmark, alternate_phone, company_name, gstin, wallet_balance, wallet_bonus_limit, referral_code, referred_by_user_id, signup_bonus_credited, first_order_completed, is_admin, admin_level) FROM stdin;
34	sreekanth	sri.chityala500@gmail.com	998969	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1500.00	10000.00	SREEKA34	\N	t	f	f	2
17	Vijay Kumar	sri.vijaychittiyala@gmail.com	D@rk#0rse	\N	7416542354	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	VIJAYK17	\N	t	f	f	2
20	vijay kumar chityala	sri.vijaychityala@gmail.com	oauth_user_no_password_P6gvG8zHXcjvzhuh	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	VIJAYK20	\N	t	f	f	2
35	sreekanth chityala	sri.chityala502@gmail.com	oauth_user_no_password_fhCA9OVQgZFJdhS9	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1500.00	10000.00	SREEKA35	\N	t	f	f	2
36	Home	sri.chityala504@gmail.com	oauth_user_no_password_uiBxRi1Ctkwu1A1n	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	HOME36	\N	t	f	f	2
27	Vishnu Chityala	vishnurchityala@gmail.com	oauth_user_no_password_iaPILT6luNGdt4Ln	\N	9537234000	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	VISHNU27	\N	t	f	f	2
15	Sreekanth Devops	sreekanththetechie@gmail.com	998969	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	500.00	10000.00	SREEKA15	\N	t	f	t	1
14	chityala srikanth	srichityala501@gmail.com		Hyderabad	7075077384	img/profiles/user_14_1775881216.png		Hyderabad	Telangana	500051	India					3500.00	10000.00	CHITYA14	\N	t	f	t	1
32	gspaces	gspaces2025@gmail.com	oauth_user_no_password_KthRRpoNZQ62vltK	hyderabad	7075077384	img/profiles/user_32_1777716604.png		hyderabad	telangana	500092	India					500.00	10000.00	GSPACE32	\N	t	f	f	1
\.


--
-- Data for Name: visitor_tracking; Type: TABLE DATA; Schema: public; Owner: sri
--

COPY public.visitor_tracking (id, visitor_id, ip_address, user_agent, country, city, region, browser, os, device_type, referrer, landing_page, first_visit, last_visit, total_visits, total_page_views, is_registered, user_id, created_at) FROM stdin;
1	visitor_9993fe698ff5b968e4e8c42678eab6dc	192.168.1.1	\N	India	Mumbai	\N	Chrome	Windows	Desktop	\N	/	2026-05-09 17:41:58.258035	2026-05-09 17:41:58.258035	1	1	f	\N	2026-05-09 17:41:58.258035
2	visitor_78ef96670f87215bfbc35e38952ba663	192.168.1.2	\N	India	Delhi	\N	Safari	iOS	Mobile	\N	/products	2026-05-09 17:41:58.258035	2026-05-09 17:41:58.258035	1	1	f	\N	2026-05-09 17:41:58.258035
3	2af1970f-349f-4b03-af34-8f4a14c2f56e	217.113.194.97	Mozilla/5.0 (compatible; Barkrowler/0.9; +https://babbar.tech/crawler)	France	Graulhet	Occitanie	crawler 	Other 	Desktop	Direct	/login	2026-05-09 17:44:37.45688	2026-05-09 17:44:37.45688	1	1	f	\N	2026-05-09 17:44:37.45688
21	ee6a6801-e06d-4e11-997d-eef5802e2516	104.210.140.136	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36; compatible; OAI-SearchBot/1.0; +https://openai.com/searchbot	Unknown	Unknown	Unknown	OAI-SearchBot 1.0	Mac OS X 10.15.7	Desktop	Direct	/robots.txt	2026-05-09 18:21:29.185241	2026-05-09 18:21:29.185241	1	1	f	\N	2026-05-09 18:21:29.185241
22	e58738db-7632-45be-ad25-c730c5e8f2f2	216.180.246.1	Mozilla/5.0 (compatible; GenomeCrawlerd/1.0; +https://www.nokia.com/genomecrawler)	Unknown	Unknown	Unknown	GenomeCrawlerd 1.0	Other 	Desktop	Direct	/	2026-05-09 18:21:33.117056	2026-05-09 18:21:33.117056	1	1	f	\N	2026-05-09 18:21:33.117056
276	13ed2f3f-8216-4efe-9b73-f01e5ae686c9	154.29.232.248	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	Unknown	Unknown	Unknown	Chrome 116.0.5845	Windows 10	Desktop	Direct	/.env	2026-05-10 02:31:04.579697	2026-05-10 02:31:04.579697	1	1	f	\N	2026-05-10 02:31:04.579697
23	af5167ad-ceb9-4cf2-9d11-8be679c6fd08	205.210.31.58	Hello from Palo Alto Networks, find out more about our scans in https://docs-cortex.paloaltonetworks.com/r/1/Cortex-Xpanse/Scanning-activity	Unknown	Unknown	Unknown	Other 	Other 	Desktop	http://www.gspaces.in/	/	2026-05-09 18:21:52.144448	2026-05-09 18:21:52.144448	1	1	f	\N	2026-05-09 18:21:52.144448
17	b1db4c05-4cae-4f68-84a6-d740e8bd2207	60.253.237.224	Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp¡±)	Unknown	Unknown	Unknown	Yahoo! Slurp 	Other 	Desktop	Direct	/	2026-05-09 18:03:17.932814	2026-05-09 18:03:17.932814	1	1	f	\N	2026-05-09 18:03:17.932814
24	0c5599bf-0f74-4170-8f88-b4b778321cac	216.180.246.1	Mozilla/5.0 (compatible; GenomeCrawlerd/1.0; +https://www.nokia.com/genomecrawler)	Unknown	Unknown	Unknown	GenomeCrawlerd 1.0	Other 	Desktop	Direct	/	2026-05-09 18:22:14.933148	2026-05-09 18:22:14.933148	1	1	f	\N	2026-05-09 18:22:14.933148
25	1c979877-8c9c-4f3b-87f3-a7b72f4b9aa0	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 18:23:07.496103	2026-05-09 18:23:07.496103	1	1	f	\N	2026-05-09 18:23:07.496103
39	b7f0cf6c-92b0-4895-9589-b658942030c2	216.73.216.13	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)	Unknown	Unknown	Unknown	ClaudeBot 1.0	Other 	Desktop	Direct	/robots.txt	2026-05-09 18:33:03.441248	2026-05-09 18:33:03.441248	1	1	f	\N	2026-05-09 18:33:03.441248
6	5f15e2e8-ac8c-499f-b998-4b07e60ce77a	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 17:46:44.536398	2026-05-09 17:46:44.536398	1	1	f	\N	2026-05-09 17:46:44.536398
281	71275c36-a85b-4f3b-a40e-8eff884ea94b	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 02:39:52.284742	2026-05-10 02:39:52.284742	1	1	f	\N	2026-05-10 02:39:52.284742
18	4b5e0166-41ed-4989-a23f-68720126cdf5	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 18:03:51.994949	2026-05-09 18:03:51.994949	1	1	f	\N	2026-05-09 18:03:51.994949
26	42deb8aa-71c0-431e-b424-376502e312dc	45.167.232.164	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.6422.141 Safari/537.36	Unknown	Unknown	Unknown	Chrome 125.0.6422	Windows 10	Desktop	Direct	/robots.txt	2026-05-09 18:25:10.90771	2026-05-09 18:25:10.90771	1	1	f	\N	2026-05-09 18:25:10.90771
27	3c6baaf9-e24f-4a0f-a5ef-58ce2289a866	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/	2026-05-09 18:25:12.614613	2026-05-09 18:25:12.614613	1	1	f	\N	2026-05-09 18:25:12.614613
19	3e57a3a3-3c86-4f04-ae9b-085f61ed769b	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 18:11:10.400668	2026-05-09 18:11:10.400668	1	1	f	\N	2026-05-09 18:11:10.400668
28	b744aa92-8d9d-46a0-a535-6e574dcc6225	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/products	2026-05-09 18:25:12.686664	2026-05-09 18:25:12.686664	1	1	f	\N	2026-05-09 18:25:12.686664
29	5cb8fd81-58a1-4ae8-945d-be145c5d0baf	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/about	2026-05-09 18:25:12.749488	2026-05-09 18:25:12.749488	1	1	f	\N	2026-05-09 18:25:12.749488
30	e83a54dc-5d22-4360-afe4-617b1a727cd1	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/contact	2026-05-09 18:25:12.791025	2026-05-09 18:25:12.791025	1	1	f	\N	2026-05-09 18:25:12.791025
31	4f379cba-a7d2-4a30-a2a6-644676d6b0f0	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/services	2026-05-09 18:25:12.82967	2026-05-09 18:25:12.82967	1	1	f	\N	2026-05-09 18:25:12.82967
8	d4c0e192-544f-4116-9e2c-6ae82c21809a	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 17:53:29.188888	2026-05-09 17:53:29.188888	1	1	f	\N	2026-05-09 17:53:29.188888
20	2f54c7dd-ac8a-4afa-b82e-050cbad6ad41	203.159.90.86	Go-http-client/1.1	Unknown	Unknown	Unknown	Go-http-client 1.1	Other 	Desktop	Direct	/.env	2026-05-09 18:16:19.667625	2026-05-09 18:16:19.667625	1	1	f	\N	2026-05-09 18:16:19.667625
9	b9101bf5-033e-4db7-91ba-4e9d451a1d53	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/	2026-05-09 18:02:14.765841	2026-05-09 18:02:14.765841	1	1	f	\N	2026-05-09 18:02:14.765841
10	ea428b9f-e861-443b-801f-59d60585ef13	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/products	2026-05-09 18:02:14.818008	2026-05-09 18:02:14.818008	1	1	f	\N	2026-05-09 18:02:14.818008
11	56f4ad25-4b33-454c-b63c-341c0cd0d472	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/about	2026-05-09 18:02:14.890641	2026-05-09 18:02:14.890641	1	1	f	\N	2026-05-09 18:02:14.890641
12	ec62ef17-b874-49c8-b46d-3b9bcab2323d	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/contact	2026-05-09 18:02:14.931095	2026-05-09 18:02:14.931095	1	1	f	\N	2026-05-09 18:02:14.931095
13	3478d5c3-dba5-4c4b-95c9-006a6819e956	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/services	2026-05-09 18:02:14.969083	2026-05-09 18:02:14.969083	1	1	f	\N	2026-05-09 18:02:14.969083
14	e75a1160-ecdc-4847-bf6c-484ce313cb8a	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/blogs	2026-05-09 18:02:15.005069	2026-05-09 18:02:15.005069	1	1	f	\N	2026-05-09 18:02:15.005069
15	dc03f34f-99d2-4bf1-ae8f-da9c1e0a1c7f	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/login	2026-05-09 18:02:15.06396	2026-05-09 18:02:15.06396	1	1	f	\N	2026-05-09 18:02:15.06396
16	7507e50b-f1fc-4c39-a78e-a166aebd1024	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/signup	2026-05-09 18:02:15.097751	2026-05-09 18:02:15.097751	1	1	f	\N	2026-05-09 18:02:15.097751
32	4fac2386-7f4d-48d3-be62-d1c5ef21aa47	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/blogs	2026-05-09 18:25:12.866168	2026-05-09 18:25:12.866168	1	1	f	\N	2026-05-09 18:25:12.866168
33	1ae9bc7d-41b5-4c85-98b4-8b465d8b0891	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/login	2026-05-09 18:25:12.923445	2026-05-09 18:25:12.923445	1	1	f	\N	2026-05-09 18:25:12.923445
34	cd469895-ee62-43f4-9dcc-7594fc9b8709	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/signup	2026-05-09 18:25:12.961067	2026-05-09 18:25:12.961067	1	1	f	\N	2026-05-09 18:25:12.961067
35	efe43d82-109e-4435-9c9d-b6401c0a638d	185.191.171.3	Mozilla/5.0 (compatible; SemrushBot/7~bl; +http://www.semrush.com/bot.html)	Unknown	Unknown	Unknown	SemrushBot 7	Other 	Desktop	Direct	/robots.txt	2026-05-09 18:26:05.118457	2026-05-09 18:26:05.118457	1	1	f	\N	2026-05-09 18:26:05.118457
36	6ae05d64-16b7-4583-aca1-6ddad8b5c5ce	185.191.171.19	Mozilla/5.0 (compatible; SemrushBot/7~bl; +http://www.semrush.com/bot.html)	Unknown	Unknown	Unknown	SemrushBot 7	Other 	Desktop	Direct	/	2026-05-09 18:26:06.168649	2026-05-09 18:26:06.168649	1	1	f	\N	2026-05-09 18:26:06.168649
43	3ac68b1c-396c-4ec0-bd55-c5665ccfa9fc	85.208.96.212	Mozilla/5.0 (compatible; SemrushBot/7~bl; +http://www.semrush.com/bot.html)	Unknown	Unknown	Unknown	SemrushBot 7	Other 	Desktop	Direct	/delete_sub_image/130	2026-05-09 19:00:59.466174	2026-05-09 19:00:59.466174	1	1	f	\N	2026-05-09 19:00:59.466174
44	2bc3f34f-03f4-4a94-b3fb-a3c20841c5a5	2a03:2880:f806:47::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	Unknown	Unknown	Unknown	meta-webindexer 1.1	Other 	Desktop	Direct	/services	2026-05-09 19:01:57.571847	2026-05-09 19:01:57.571847	1	1	f	\N	2026-05-09 19:01:57.571847
45	7367faa4-00e2-4d39-a098-d8cd7fb7195c	3.130.168.2	visionheight.com/scan Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/126.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 126.0.0	Mac OS X 10.15.7	Desktop	Direct	/	2026-05-09 19:05:02.994338	2026-05-09 19:05:02.994338	1	1	f	\N	2026-05-09 19:05:02.994338
46	32946995-2872-4f2c-8dac-21a055c3fddd	3.130.168.2	visionheight.com/scan Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/126.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 126.0.0	Mac OS X 10.15.7	Desktop	Direct	/	2026-05-09 19:05:48.330308	2026-05-09 19:05:48.330308	1	1	f	\N	2026-05-09 19:05:48.330308
37	06d3dcef-9c97-4f06-b590-a053b7a95c6b	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 18:29:49.812618	2026-05-09 18:29:49.812618	1	1	f	\N	2026-05-09 18:29:49.812618
47	4975d471-53be-4026-a3e3-89b28f5aa219	51.68.247.194	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	Unknown	Unknown	Unknown	AhrefsBot 7.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-09 19:11:40.254136	2026-05-09 19:11:40.254136	1	1	f	\N	2026-05-09 19:11:40.254136
48	9c4e4ffb-1ccf-461e-acdb-df36cd3d253e	216.10.27.45	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	Unknown	Unknown	Unknown	Chrome 116.0.5845	Windows 10	Desktop	Direct	/.env	2026-05-09 19:11:54.33039	2026-05-09 19:11:54.33039	1	1	f	\N	2026-05-09 19:11:54.33039
49	665e0b28-9b99-46d7-9a5d-bfd2ac249985	216.10.27.45	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	Unknown	Unknown	Unknown	Chrome 116.0.5845	Windows 10	Desktop	Direct	/	2026-05-09 19:11:55.140257	2026-05-09 19:11:55.140257	1	1	f	\N	2026-05-09 19:11:55.140257
50	23fed778-0871-4791-86f7-eb0f244b9cb1	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 19:13:42.990003	2026-05-09 19:13:42.990003	1	1	f	\N	2026-05-09 19:13:42.990003
51	3058b4a9-ce43-4d81-a369-9b15877a3ec1	85.208.96.194	Mozilla/5.0 (compatible; SemrushBot/7~bl; +http://www.semrush.com/bot.html)	Unknown	Unknown	Unknown	SemrushBot 7	Other 	Desktop	Direct	/delete_sub_image/131	2026-05-09 19:14:01.15077	2026-05-09 19:14:01.15077	1	1	f	\N	2026-05-09 19:14:01.15077
4	730254b5-c888-4bcb-bbce-53ffc2ffff5d	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	India	Hyderabad	Telangana	Chrome 147.0.0	Mac OS X 10.15.7	Desktop	Direct	/admin/deals	2026-05-09 17:44:53.85143	2026-05-09 19:14:32.297254	269	269	t	14	2026-05-09 17:44:53.85143
38	935c8ab2-1a0f-4e6f-9039-e10b98e7ed0c	216.180.246.1	Mozilla/5.0 (compatible; GenomeCrawlerd/1.0; +https://www.nokia.com/genomecrawler)	Unknown	Unknown	Unknown	GenomeCrawlerd 1.0	Other 	Desktop	Direct	/	2026-05-09 18:32:34.692106	2026-05-09 18:32:34.692106	1	1	f	\N	2026-05-09 18:32:34.692106
7	03537714-734f-4b72-aaf0-42bda7ae02b8	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	Unknown	Unknown	Unknown	Chrome Mobile 148.0.0	Android 10	Mobile	Direct	/	2026-05-09 17:51:08.961182	2026-05-09 19:14:55.546956	6	6	f	\N	2026-05-09 17:51:08.961182
52	60c63a2c-6372-43b8-885f-126d95544f1e	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	Unknown	Unknown	Unknown	Chrome Mobile 148.0.0	Android 10	Mobile	Direct	/	2026-05-09 19:15:05.709587	2026-05-09 19:16:00.541843	7	7	f	\N	2026-05-09 19:15:05.709587
53	22275a15-fb71-40f3-a7bb-f6dc25d84a37	2406:b400:b4:b6a:cff:c699:f868:4ff2	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 147.0.0	Mac OS X 10.15.7	Desktop	Direct	/	2026-05-09 19:18:52.370417	2026-05-09 19:18:52.370417	1	1	f	\N	2026-05-09 19:18:52.370417
54	d91d11f0-2601-43c0-a11d-22ef81ff88a6	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	Unknown	Unknown	Unknown	Claude-SearchBot 1.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-09 19:20:53.832392	2026-05-09 19:20:53.832392	1	1	f	\N	2026-05-09 19:20:53.832392
55	aa8b0498-ba83-4d5d-9029-406aee410c6c	43.129.169.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 106.0.0	Windows 10	Desktop	Direct	/Core/Skin/Login.aspx	2026-05-09 19:23:30.945844	2026-05-09 19:23:30.945844	1	1	f	\N	2026-05-09 19:23:30.945844
56	937daf18-0e92-447e-97da-64420409be96	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 19:25:00.316292	2026-05-09 19:25:00.316292	1	1	f	\N	2026-05-09 19:25:00.316292
40	c3ad20fd-94ff-47d5-9dfe-6ad77a7f6477	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 18:48:19.213796	2026-05-09 18:48:19.213796	1	1	f	\N	2026-05-09 18:48:19.213796
57	aea7f32b-57d6-4514-a61d-c3f2b07476ce	112.86.225.39	Sogou web spider/4.0(+http://www.sogou.com/docs/help/webmasters.htm#07)	Unknown	Unknown	Unknown	Sogou web spider 4.0	Other 	Desktop	Direct	/	2026-05-09 19:25:51.213984	2026-05-09 19:25:51.213984	1	1	f	\N	2026-05-09 19:25:51.213984
58	12eb46ea-ae6e-4e99-a136-aa1457a1f3c6	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 19:30:26.543258	2026-05-09 19:30:26.543258	1	1	f	\N	2026-05-09 19:30:26.543258
41	07909004-1680-4a0e-8b66-71ba219b2b14	206.189.1.73	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.129 Safari/537.36	The Netherlands	Amsterdam	North Holland	Chrome 81.0.4044	Linux 	Desktop	Direct	/backend/app/.git/config	2026-05-09 18:56:28.170318	2026-05-09 18:56:28.170318	1	1	f	\N	2026-05-09 18:56:28.170318
42	afeb4f9e-606e-4ad2-8a13-8520c2526aac	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 18:58:27.365145	2026-05-09 18:58:27.365145	1	1	f	\N	2026-05-09 18:58:27.365145
59	7130629e-3b57-4086-bc2e-7d3632ef443a	2a03:2880:f806:6::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	Unknown	Unknown	Unknown	meta-webindexer 1.1	Other 	Desktop	Direct	/product/24	2026-05-09 19:34:27.830874	2026-05-09 19:34:27.830874	1	1	f	\N	2026-05-09 19:34:27.830874
60	790d3c4f-f90b-489c-8dea-6f84b955b512	2a03:2880:f806:1a::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	Unknown	Unknown	Unknown	meta-webindexer 1.1	Other 	Desktop	Direct	/my-workspace	2026-05-09 19:34:48.392877	2026-05-09 19:34:48.392877	1	1	f	\N	2026-05-09 19:34:48.392877
61	3d286c2b-407a-4629-b2af-62561c8092e7	2a03:2880:f806:15::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	Unknown	Unknown	Unknown	meta-webindexer 1.1	Other 	Desktop	Direct	/login	2026-05-09 19:35:12.027413	2026-05-09 19:35:12.027413	1	1	f	\N	2026-05-09 19:35:12.027413
62	74158840-f518-484e-8b8e-8853bc40f2e7	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/etc/passwd	2026-05-09 19:36:49.304266	2026-05-09 19:36:49.304266	1	1	f	\N	2026-05-09 19:36:49.304266
63	b4286ff7-5413-467e-b7ce-053561a39a62	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/etc/passwd	2026-05-09 19:36:49.475195	2026-05-09 19:36:49.475195	1	1	f	\N	2026-05-09 19:36:49.475195
64	c37a9b2e-3e22-4566-9755-19353afa1f12	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/etc/passwd	2026-05-09 19:36:49.640732	2026-05-09 19:36:49.640732	1	1	f	\N	2026-05-09 19:36:49.640732
65	0bcbfb52-0e7b-4991-9536-06395f5f18db	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/etc/passwd	2026-05-09 19:36:49.809021	2026-05-09 19:36:49.809021	1	1	f	\N	2026-05-09 19:36:49.809021
66	2838a882-76f5-4484-a856-6c0382267e01	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/etc/shadow	2026-05-09 19:36:49.974347	2026-05-09 19:36:49.974347	1	1	f	\N	2026-05-09 19:36:49.974347
67	a0ff33fc-b73a-45f4-8eb5-e67f61cf32ab	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/etc/shadow	2026-05-09 19:36:50.14759	2026-05-09 19:36:50.14759	1	1	f	\N	2026-05-09 19:36:50.14759
68	6183ce65-450f-48ed-a822-ec11ee15aaec	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/etc/shadow	2026-05-09 19:36:50.312603	2026-05-09 19:36:50.312603	1	1	f	\N	2026-05-09 19:36:50.312603
69	be09c0ed-c088-469b-a210-d3d5de900496	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/etc/shadow	2026-05-09 19:36:50.480746	2026-05-09 19:36:50.480746	1	1	f	\N	2026-05-09 19:36:50.480746
70	f045ecf6-b37f-4bfe-b0fe-dd2de504ab94	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/proc/self/environ	2026-05-09 19:36:50.649137	2026-05-09 19:36:50.649137	1	1	f	\N	2026-05-09 19:36:50.649137
71	0d8e946a-f080-4004-bbd7-72463a9e3ae2	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/proc/self/environ	2026-05-09 19:36:50.816201	2026-05-09 19:36:50.816201	1	1	f	\N	2026-05-09 19:36:50.816201
72	ff37723f-d864-4cc0-8797-67f106c493a0	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/proc/self/environ	2026-05-09 19:36:50.986973	2026-05-09 19:36:50.986973	1	1	f	\N	2026-05-09 19:36:50.986973
73	66ae1903-229a-47ca-8d53-61356a49b6ac	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/proc/self/environ	2026-05-09 19:36:51.156955	2026-05-09 19:36:51.156955	1	1	f	\N	2026-05-09 19:36:51.156955
74	b16a9af9-1c57-4aec-994f-1ac0ffbd094b	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/proc/self/cmdline	2026-05-09 19:36:51.325966	2026-05-09 19:36:51.325966	1	1	f	\N	2026-05-09 19:36:51.325966
75	e0d2d276-bfe9-4bc8-a455-83fccc28337d	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/proc/self/cmdline	2026-05-09 19:36:51.49337	2026-05-09 19:36:51.49337	1	1	f	\N	2026-05-09 19:36:51.49337
76	e5d9a50a-734d-4d83-8090-59a9679312ea	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/proc/self/cmdline	2026-05-09 19:36:51.659332	2026-05-09 19:36:51.659332	1	1	f	\N	2026-05-09 19:36:51.659332
77	9f6cbf4b-88b6-4796-bd5e-b5059a567493	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/proc/self/cmdline	2026-05-09 19:36:51.828099	2026-05-09 19:36:51.828099	1	1	f	\N	2026-05-09 19:36:51.828099
78	11b1f26c-3173-46a6-ba20-c257ec2b964c	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env	2026-05-09 19:36:51.999608	2026-05-09 19:36:51.999608	1	1	f	\N	2026-05-09 19:36:51.999608
79	3e2aac0d-4b61-420c-b858-2b4dfbecdc61	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env	2026-05-09 19:36:52.16863	2026-05-09 19:36:52.16863	1	1	f	\N	2026-05-09 19:36:52.16863
80	0c6d0f23-9cfd-41f8-a586-c65d0ba25311	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env	2026-05-09 19:36:52.344379	2026-05-09 19:36:52.344379	1	1	f	\N	2026-05-09 19:36:52.344379
81	a3dabc97-668c-432b-9d19-b416bf672976	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env	2026-05-09 19:36:52.511961	2026-05-09 19:36:52.511961	1	1	f	\N	2026-05-09 19:36:52.511961
82	0ec32fa5-afa1-4929-9a8f-2b56219bfe95	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env.local	2026-05-09 19:36:52.678769	2026-05-09 19:36:52.678769	1	1	f	\N	2026-05-09 19:36:52.678769
83	3ae52c6e-5193-40b7-a31c-1021aec6244e	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env.local	2026-05-09 19:36:52.845548	2026-05-09 19:36:52.845548	1	1	f	\N	2026-05-09 19:36:52.845548
84	94187e40-9fcc-451d-8279-55757174dcf4	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env.local	2026-05-09 19:36:53.014389	2026-05-09 19:36:53.014389	1	1	f	\N	2026-05-09 19:36:53.014389
85	76242a2d-d6a0-406a-b758-eb4aca238d00	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env.local	2026-05-09 19:36:53.189554	2026-05-09 19:36:53.189554	1	1	f	\N	2026-05-09 19:36:53.189554
86	e5d0ecb9-f14c-4470-89e0-1ef27d63fe73	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env.production	2026-05-09 19:36:53.353168	2026-05-09 19:36:53.353168	1	1	f	\N	2026-05-09 19:36:53.353168
87	e7d41253-dbb1-45b1-b9fd-24ce16040913	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env.production	2026-05-09 19:36:53.52512	2026-05-09 19:36:53.52512	1	1	f	\N	2026-05-09 19:36:53.52512
88	b2853330-d9af-4047-8bdc-db951ce5f569	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env.production	2026-05-09 19:36:53.69476	2026-05-09 19:36:53.69476	1	1	f	\N	2026-05-09 19:36:53.69476
89	268bf177-4ebb-4a32-9b14-678f87a3d8c2	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env.production	2026-05-09 19:36:53.85854	2026-05-09 19:36:53.85854	1	1	f	\N	2026-05-09 19:36:53.85854
90	949f9f3f-816c-4939-9c4d-3f64d2059556	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env.development	2026-05-09 19:36:54.02475	2026-05-09 19:36:54.02475	1	1	f	\N	2026-05-09 19:36:54.02475
91	c1b576a1-651b-4f8b-b3f6-4bd379bb70a3	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env.development	2026-05-09 19:36:54.191499	2026-05-09 19:36:54.191499	1	1	f	\N	2026-05-09 19:36:54.191499
92	382d3df2-0339-4ca3-acb3-6f66dba079fb	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env.development	2026-05-09 19:36:54.358639	2026-05-09 19:36:54.358639	1	1	f	\N	2026-05-09 19:36:54.358639
93	a107cc7f-c727-4d42-9143-d8e0bbccdd8f	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.env.development	2026-05-09 19:36:54.525236	2026-05-09 19:36:54.525236	1	1	f	\N	2026-05-09 19:36:54.525236
94	da60cb2b-c478-4a79-b9b9-44fb57e12aa9	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/home/node/.env	2026-05-09 19:36:54.691653	2026-05-09 19:36:54.691653	1	1	f	\N	2026-05-09 19:36:54.691653
95	70a4d6af-9c3b-4ee3-9411-ab0dafc0e8f6	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/home/node/.env	2026-05-09 19:36:54.860748	2026-05-09 19:36:54.860748	1	1	f	\N	2026-05-09 19:36:54.860748
96	6a848a37-6f0a-47f0-b4d6-0ecab839fec2	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/home/node/.env	2026-05-09 19:36:55.027537	2026-05-09 19:36:55.027537	1	1	f	\N	2026-05-09 19:36:55.027537
97	2d0ca737-be55-4fff-8747-1c793db0e22e	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/home/node/.env	2026-05-09 19:36:55.192634	2026-05-09 19:36:55.192634	1	1	f	\N	2026-05-09 19:36:55.192634
98	93b3abfe-140c-4e9a-976b-ee0a9d5b4ca4	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/root/.env	2026-05-09 19:36:55.355902	2026-05-09 19:36:55.355902	1	1	f	\N	2026-05-09 19:36:55.355902
99	bb75eaa2-7cde-4193-b359-8dbe7236f265	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/root/.env	2026-05-09 19:36:55.520637	2026-05-09 19:36:55.520637	1	1	f	\N	2026-05-09 19:36:55.520637
100	137f1d07-4231-4b37-a470-d25847c15fa6	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/root/.env	2026-05-09 19:36:55.687763	2026-05-09 19:36:55.687763	1	1	f	\N	2026-05-09 19:36:55.687763
101	e56798e4-2edb-4ac5-b9da-dee140509c32	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/root/.env	2026-05-09 19:36:55.853471	2026-05-09 19:36:55.853471	1	1	f	\N	2026-05-09 19:36:55.853471
102	d13df28a-e47c-44ca-ac7f-848937672712	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/config/default.json	2026-05-09 19:36:56.021462	2026-05-09 19:36:56.021462	1	1	f	\N	2026-05-09 19:36:56.021462
103	8dabad15-7b04-456b-b4d4-457392768d25	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/config/default.json	2026-05-09 19:36:56.186882	2026-05-09 19:36:56.186882	1	1	f	\N	2026-05-09 19:36:56.186882
104	ac5c6375-50ea-4eb2-bee5-519a159dd4df	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/config/default.json	2026-05-09 19:36:56.351346	2026-05-09 19:36:56.351346	1	1	f	\N	2026-05-09 19:36:56.351346
105	cf183c45-a14a-43a8-ba18-2163427fa3f5	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/config/default.json	2026-05-09 19:36:56.518755	2026-05-09 19:36:56.518755	1	1	f	\N	2026-05-09 19:36:56.518755
106	d763708b-ffe5-451c-a084-f20d0a3fe320	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/config/production.json	2026-05-09 19:36:56.69237	2026-05-09 19:36:56.69237	1	1	f	\N	2026-05-09 19:36:56.69237
107	f1a297a3-d8d8-47fb-aa65-0a9d8451e4b4	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/config/production.json	2026-05-09 19:36:56.859018	2026-05-09 19:36:56.859018	1	1	f	\N	2026-05-09 19:36:56.859018
108	7a620232-e9b4-4f3f-9387-f1de42a18963	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/config/production.json	2026-05-09 19:36:57.027526	2026-05-09 19:36:57.027526	1	1	f	\N	2026-05-09 19:36:57.027526
109	ecc87528-986c-4f71-ab74-01d20d3cbbc0	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/config/production.json	2026-05-09 19:36:57.194017	2026-05-09 19:36:57.194017	1	1	f	\N	2026-05-09 19:36:57.194017
110	131fffba-acc7-4127-b055-101d7b6b40e7	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.npmrc	2026-05-09 19:36:57.364415	2026-05-09 19:36:57.364415	1	1	f	\N	2026-05-09 19:36:57.364415
111	e3b51c87-7cf9-4f04-a703-cdbc56c7a191	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.npmrc	2026-05-09 19:36:57.532489	2026-05-09 19:36:57.532489	1	1	f	\N	2026-05-09 19:36:57.532489
112	4ba34ebd-b51a-4496-887c-718db7c0fb65	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.npmrc	2026-05-09 19:36:57.701989	2026-05-09 19:36:57.701989	1	1	f	\N	2026-05-09 19:36:57.701989
113	e2b69c90-72e6-48be-824b-e522761bae94	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/.npmrc	2026-05-09 19:36:57.867443	2026-05-09 19:36:57.867443	1	1	f	\N	2026-05-09 19:36:57.867443
114	d6dc9363-77d2-4714-a551-e3db66c26b30	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/vite.config.ts	2026-05-09 19:36:58.033685	2026-05-09 19:36:58.033685	1	1	f	\N	2026-05-09 19:36:58.033685
115	5c4850da-241a-4cb9-bf3c-827acaa68ba6	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/vite.config.ts	2026-05-09 19:36:58.201603	2026-05-09 19:36:58.201603	1	1	f	\N	2026-05-09 19:36:58.201603
116	3646b899-d92a-4a92-a789-8b0c07ac3d00	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/vite.config.ts	2026-05-09 19:36:58.367259	2026-05-09 19:36:58.367259	1	1	f	\N	2026-05-09 19:36:58.367259
117	10758c18-6da8-49c7-b6b8-b98ec2add148	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/vite.config.ts	2026-05-09 19:36:58.549657	2026-05-09 19:36:58.549657	1	1	f	\N	2026-05-09 19:36:58.549657
118	ba5cfc29-958a-4259-a36e-18cd8ff6bf6a	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/vite.config.js	2026-05-09 19:36:58.720563	2026-05-09 19:36:58.720563	1	1	f	\N	2026-05-09 19:36:58.720563
119	cd713f9c-9f33-40e6-b329-a749d1f691b9	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/vite.config.js	2026-05-09 19:36:58.884473	2026-05-09 19:36:58.884473	1	1	f	\N	2026-05-09 19:36:58.884473
120	a92ace81-ff1b-4194-b3db-6294ebfc11fd	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/vite.config.js	2026-05-09 19:36:59.055754	2026-05-09 19:36:59.055754	1	1	f	\N	2026-05-09 19:36:59.055754
121	a4950bf1-fe0f-4743-8559-96078b33e3fb	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/vite.config.js	2026-05-09 19:36:59.2261	2026-05-09 19:36:59.2261	1	1	f	\N	2026-05-09 19:36:59.2261
122	f8a57d89-7714-4100-99dc-4517849155de	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/docker-compose.yml	2026-05-09 19:36:59.39952	2026-05-09 19:36:59.39952	1	1	f	\N	2026-05-09 19:36:59.39952
123	89a1dfd5-f2ef-4650-81ff-d0834e707bf8	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/docker-compose.yml	2026-05-09 19:36:59.567655	2026-05-09 19:36:59.567655	1	1	f	\N	2026-05-09 19:36:59.567655
124	901ca61f-eb97-416e-9867-e56c2d743168	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/docker-compose.yml	2026-05-09 19:36:59.755792	2026-05-09 19:36:59.755792	1	1	f	\N	2026-05-09 19:36:59.755792
125	e3869ce3-1073-4ab3-98c9-ae95fc6b18ec	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/docker-compose.yml	2026-05-09 19:36:59.92589	2026-05-09 19:36:59.92589	1	1	f	\N	2026-05-09 19:36:59.92589
126	44179de7-5b68-45b4-be25-697fc538b03f	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/Dockerfile	2026-05-09 19:37:00.089706	2026-05-09 19:37:00.089706	1	1	f	\N	2026-05-09 19:37:00.089706
127	eccf0322-0c83-4d83-866f-3e7febeaf035	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/Dockerfile	2026-05-09 19:37:00.253582	2026-05-09 19:37:00.253582	1	1	f	\N	2026-05-09 19:37:00.253582
128	afd77117-5d3d-4ee7-9be5-d9894c81274a	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/Dockerfile	2026-05-09 19:37:00.419846	2026-05-09 19:37:00.419846	1	1	f	\N	2026-05-09 19:37:00.419846
129	7de65b58-3f21-485a-b8fb-a9f05e1e2dfc	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/app/Dockerfile	2026-05-09 19:37:00.585215	2026-05-09 19:37:00.585215	1	1	f	\N	2026-05-09 19:37:00.585215
130	af8b0052-7879-43ed-b0bf-2750cd6b8cb2	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/home/node/.bash_history	2026-05-09 19:37:00.750379	2026-05-09 19:37:00.750379	1	1	f	\N	2026-05-09 19:37:00.750379
131	f05478a3-2bac-4e6e-b386-33b7771dcbcb	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/home/node/.bash_history	2026-05-09 19:37:00.916536	2026-05-09 19:37:00.916536	1	1	f	\N	2026-05-09 19:37:00.916536
350	sample_visitor_1	192.168.1.1	\N	India	Mumbai	\N	Chrome	Windows	desktop	\N	\N	2026-05-10 06:32:24.175695	2026-05-10 06:32:24.175695	1	1	f	\N	2026-05-10 06:32:24.175695
132	393fb124-98b7-4d51-8d2f-ad1fb10e9705	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/home/node/.bash_history	2026-05-09 19:37:01.082798	2026-05-09 19:37:01.082798	1	1	f	\N	2026-05-09 19:37:01.082798
133	5a44d90f-6e23-4d2b-890a-dab55dd8c94d	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/home/node/.bash_history	2026-05-09 19:37:01.248314	2026-05-09 19:37:01.248314	1	1	f	\N	2026-05-09 19:37:01.248314
134	f357c7ad-085f-433d-a39c-681799289ae5	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/root/.bash_history	2026-05-09 19:37:01.419227	2026-05-09 19:37:01.419227	1	1	f	\N	2026-05-09 19:37:01.419227
135	7c8e60ee-aa7c-4df2-aeb1-01ab416460c3	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/root/.bash_history	2026-05-09 19:37:01.589901	2026-05-09 19:37:01.589901	1	1	f	\N	2026-05-09 19:37:01.589901
136	2ed958ff-cb09-491c-ad86-dd41aa3cea2c	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/root/.bash_history	2026-05-09 19:37:01.754744	2026-05-09 19:37:01.754744	1	1	f	\N	2026-05-09 19:37:01.754744
137	2b9b1c88-bbff-4f79-b572-60f4b736cb16	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/root/.bash_history	2026-05-09 19:37:01.922651	2026-05-09 19:37:01.922651	1	1	f	\N	2026-05-09 19:37:01.922651
138	88312611-aa09-4738-898b-30dda48e37a6	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/home/node/.bashrc	2026-05-09 19:37:02.086891	2026-05-09 19:37:02.086891	1	1	f	\N	2026-05-09 19:37:02.086891
139	da583325-a085-4f8e-bdad-a5b99e582c23	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/home/node/.bashrc	2026-05-09 19:37:02.25101	2026-05-09 19:37:02.25101	1	1	f	\N	2026-05-09 19:37:02.25101
140	786d0a4f-2df0-4235-9f77-93ce089f1326	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/home/node/.bashrc	2026-05-09 19:37:02.416098	2026-05-09 19:37:02.416098	1	1	f	\N	2026-05-09 19:37:02.416098
141	c2f5f833-8a79-4591-97b8-3cc0be79d3d5	204.76.203.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 124.0.0	Windows 10	Desktop	Direct	/@fs/home/node/.bashrc	2026-05-09 19:37:02.581937	2026-05-09 19:37:02.581937	1	1	f	\N	2026-05-09 19:37:02.581937
142	5cf3c945-d0a5-4b89-b07c-860def09478d	23.23.97.185	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amzn-SearchBot/0.1) Chrome/119.0.6045.214 Safari/537.36	Unknown	Unknown	Unknown	Amzn-SearchBot 0.1	Other 	Desktop	Direct	/forgot_password	2026-05-09 19:40:38.466892	2026-05-09 19:40:38.466892	1	1	f	\N	2026-05-09 19:40:38.466892
143	c16f50ee-a915-4f28-bc4a-c15e4486c3bb	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 19:41:39.100439	2026-05-09 19:41:39.100439	1	1	f	\N	2026-05-09 19:41:39.100439
144	db6d2ce7-1422-4884-81d6-5afbe1cf7674	54.197.241.196	Mozilla/5.0 AppleWebKit/605.1.15 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/605.1.15	Unknown	Unknown	Unknown	Chrome 139.0.0	Other 	Desktop	Direct	/forgot_password	2026-05-09 19:42:07.26284	2026-05-09 19:42:07.26284	1	1	f	\N	2026-05-09 19:42:07.26284
145	6b397234-fa7c-444e-be79-925415e5c955	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 19:51:36.427329	2026-05-09 19:51:36.427329	1	1	f	\N	2026-05-09 19:51:36.427329
146	96f8aadd-fce8-4ddf-b230-de270186cbae	45.38.78.226	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	Unknown	Unknown	Unknown	Chrome 116.0.5845	Windows 10	Desktop	Direct	/.env	2026-05-09 19:52:50.115785	2026-05-09 19:52:50.115785	1	1	f	\N	2026-05-09 19:52:50.115785
147	d0040593-0b2f-4c66-bc0d-9cdce3752397	45.38.78.226	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	Unknown	Unknown	Unknown	Chrome 116.0.5845	Windows 10	Desktop	Direct	/	2026-05-09 19:52:50.991169	2026-05-09 19:52:50.991169	1	1	f	\N	2026-05-09 19:52:50.991169
148	bf822b4c-8875-46a7-8616-f8aaa4236e83	101.32.208.70	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Unknown	Unknown	Unknown	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	http://gspaces.in	/	2026-05-09 19:54:24.952444	2026-05-09 19:54:24.952444	1	1	f	\N	2026-05-09 19:54:24.952444
149	307cc576-b476-451d-b998-5583890159b3	2a03:2880:f806:13::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	Unknown	Unknown	Unknown	meta-webindexer 1.1	Other 	Desktop	Direct	/sitemap.xml	2026-05-09 19:57:14.039563	2026-05-09 19:57:14.039563	1	1	f	\N	2026-05-09 19:57:14.039563
150	9559563f-6519-4bce-b8be-8ce6730cdf6f	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 19:57:25.096196	2026-05-09 19:57:25.096196	1	1	f	\N	2026-05-09 19:57:25.096196
151	8e7e03b6-aae5-4124-b092-8ea3c5c0b9e1	2a03:2880:f806:51::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	United States	Atlanta	Georgia	meta-webindexer 1.1	Other 	Desktop	Direct	/news_sitemap.xml	2026-05-09 20:04:05.467334	2026-05-09 20:04:05.467334	1	1	f	\N	2026-05-09 20:04:05.467334
152	7cfda39a-fd37-43d0-b64a-4b0237464bd5	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 20:05:21.887268	2026-05-09 20:05:21.887268	1	1	f	\N	2026-05-09 20:05:21.887268
153	0beeb4fd-35d7-44fa-9039-7586b6600119	92.222.108.96	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	France	Paris	Île-de-France	AhrefsBot 7.0	Other 	Desktop	Direct	/edit_sub_image/122	2026-05-09 20:05:54.223589	2026-05-09 20:05:54.223589	1	1	f	\N	2026-05-09 20:05:54.223589
154	72f9bfac-6b41-41d1-a2c5-fc5d7972200d	98.84.242.117	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amzn-SearchBot/0.1) Chrome/119.0.6045.214 Safari/537.36	United States	Ashburn	Virginia	Amzn-SearchBot 0.1	Other 	Desktop	Direct	/product/25	2026-05-09 20:14:58.717292	2026-05-09 20:14:58.717292	1	1	f	\N	2026-05-09 20:14:58.717292
155	897fa2c4-c684-43dd-ab42-e44eabb40b83	35.168.48.89	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amzn-SearchBot/0.1) Chrome/119.0.6045.214 Safari/537.36	United States	Ashburn	Virginia	Amzn-SearchBot 0.1	Other 	Desktop	Direct	/product/23	2026-05-09 20:15:08.705082	2026-05-09 20:15:08.705082	1	1	f	\N	2026-05-09 20:15:08.705082
156	51aa7895-4073-49e5-8fcc-ee27d81bd15a	170.106.192.3	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	United States	Santa Clara	California	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	Direct	/my-workspace	2026-05-09 20:15:57.23984	2026-05-09 20:15:57.23984	1	1	f	\N	2026-05-09 20:15:57.23984
157	577bb2c0-dc27-4149-b172-3f03536ae5d3	170.106.192.3	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	United States	Santa Clara	California	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	https://gspaces.in/my-workspace	/login	2026-05-09 20:15:58.386539	2026-05-09 20:15:58.386539	1	1	f	\N	2026-05-09 20:15:58.386539
158	e080469a-ac8a-4bb7-a636-4695191421c8	37.59.204.130	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	Belgium	Zaventem	Flanders	AhrefsBot 7.0	Other 	Desktop	Direct	/privacy	2026-05-09 20:17:07.534705	2026-05-09 20:17:07.534705	1	1	f	\N	2026-05-09 20:17:07.534705
159	4313dc9d-3434-4ad3-a553-b9cc80f54dad	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 20:18:34.825005	2026-05-09 20:18:34.825005	1	1	f	\N	2026-05-09 20:18:34.825005
160	c67fe569-0903-440c-81ad-4d40b1e27a3f	205.210.31.2	Hello from Palo Alto Networks, find out more about our scans in https://docs-cortex.paloaltonetworks.com/r/1/Cortex-Xpanse/Scanning-activity	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 20:19:16.632775	2026-05-09 20:19:16.632775	1	1	f	\N	2026-05-09 20:19:16.632775
161	3cc8bb22-8b37-4870-a10e-0e1c9f6e5c5d	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 20:25:15.954586	2026-05-09 20:25:15.954586	1	1	f	\N	2026-05-09 20:25:15.954586
162	f47ea3fc-6962-4fd4-932b-7742c7f5ad29	223.109.252.209	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 144.0.0	Windows 10	Desktop	Direct	/uono/tatti-ka-game-40698t4.pdf	2026-05-09 20:26:30.657528	2026-05-09 20:26:30.657528	1	1	f	\N	2026-05-09 20:26:30.657528
163	494925ab-ce7d-48fd-a055-a8f1b71f7401	216.73.216.13	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)	Unknown	Unknown	Unknown	ClaudeBot 1.0	Other 	Desktop	Direct	/robots.txt	2026-05-09 20:30:02.215236	2026-05-09 20:30:02.215236	1	1	f	\N	2026-05-09 20:30:02.215236
164	c50c78ea-28d1-4659-aa43-37132a409516	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 20:31:45.784857	2026-05-09 20:31:45.784857	1	1	f	\N	2026-05-09 20:31:45.784857
165	9622e433-f0a4-4b24-9c32-a530f0ae8cf1	37.59.204.129	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	Unknown	Unknown	Unknown	AhrefsBot 7.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-09 20:37:06.179771	2026-05-09 20:37:06.179771	1	1	f	\N	2026-05-09 20:37:06.179771
166	2f61d8a4-7d64-4d79-9f20-ea917e35d1fc	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 20:40:09.349397	2026-05-09 20:40:09.349397	1	1	f	\N	2026-05-09 20:40:09.349397
167	56864e13-b519-4737-b3d8-ec322a51e131	37.59.204.143	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	Unknown	Unknown	Unknown	AhrefsBot 7.0	Other 	Desktop	Direct	/delete_sub_image/122	2026-05-09 20:47:33.847777	2026-05-09 20:47:33.847777	1	1	f	\N	2026-05-09 20:47:33.847777
168	5e5084ba-8fd1-4820-9650-379990cab21c	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 20:50:33.929427	2026-05-09 20:50:33.929427	1	1	f	\N	2026-05-09 20:50:33.929427
169	46522bf8-08cd-4d42-98d0-b2ba24e5f23b	43.130.105.21	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Unknown	Unknown	Unknown	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	Direct	/	2026-05-09 20:52:22.377602	2026-05-09 20:52:22.377602	1	1	f	\N	2026-05-09 20:52:22.377602
170	e85f5a2f-2d3d-4555-a02f-12926162595a	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 20:59:41.005419	2026-05-09 20:59:41.005419	1	1	f	\N	2026-05-09 20:59:41.005419
171	f96be018-1ad3-4a8a-930e-57bcd18664d9	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	Unknown	Unknown	Unknown	Claude-SearchBot 1.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-09 21:00:12.027574	2026-05-09 21:00:12.027574	1	1	f	\N	2026-05-09 21:00:12.027574
172	c52889a3-79e1-4512-9cf0-7444cb8b224d	2a03:2880:f806:4::	facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)	Unknown	Unknown	Unknown	FacebookBot 1.1	Other 	Desktop	Direct	/robots.txt	2026-05-09 21:01:33.328516	2026-05-09 21:01:33.328516	1	1	f	\N	2026-05-09 21:01:33.328516
173	200501b7-7871-4b3e-95d3-27076855d5de	43.129.169.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 106.0.0	Windows 10	Desktop	Direct	/Core/Skin/Login.aspx	2026-05-09 21:01:36.202478	2026-05-09 21:01:36.202478	1	1	f	\N	2026-05-09 21:01:36.202478
174	69bfbef0-37e4-465f-95b9-ad7e27be5d8d	2a03:2880:f806:27::	facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)	Unknown	Unknown	Unknown	FacebookBot 1.1	Other 	Desktop	Direct	/robots.txt	2026-05-09 21:05:14.628275	2026-05-09 21:05:14.628275	1	1	f	\N	2026-05-09 21:05:14.628275
175	c811c043-86f6-48d0-afd8-e7f5315d1b61	2a03:2880:f806:1::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	Unknown	Unknown	Unknown	meta-webindexer 1.1	Other 	Desktop	Direct	/shop.html	2026-05-09 21:05:20.121756	2026-05-09 21:05:20.121756	1	1	f	\N	2026-05-09 21:05:20.121756
176	b4460f42-03ad-42f6-96ac-3b3b88243329	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 21:09:04.784317	2026-05-09 21:09:04.784317	1	1	f	\N	2026-05-09 21:09:04.784317
177	125f78f9-de5b-4c26-b98b-516ac69203bd	43.157.46.118	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Unknown	Unknown	Unknown	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	Direct	/my-workspace	2026-05-09 21:10:04.149883	2026-05-09 21:10:04.149883	1	1	f	\N	2026-05-09 21:10:04.149883
178	a0cce080-621f-4109-99de-17c2de7e3c0d	43.157.46.118	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Unknown	Unknown	Unknown	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	http://3.7.69.151:80/my-workspace	/login	2026-05-09 21:10:05.855455	2026-05-09 21:10:05.855455	1	1	f	\N	2026-05-09 21:10:05.855455
179	e5bf89cb-9d7e-4478-b74f-2942729d642e	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 21:15:13.469268	2026-05-09 21:15:13.469268	1	1	f	\N	2026-05-09 21:15:13.469268
180	87854063-5547-4a0b-aecd-9e8929a0ee31	135.237.126.203	Mozilla/5.0 zgrab/0.x	United States	Washington	Virginia	Other 	Other 	Desktop	Direct	/	2026-05-09 21:24:06.569325	2026-05-09 21:24:06.569325	1	1	f	\N	2026-05-09 21:24:06.569325
181	67618c28-0730-44a9-8bce-80f9e75c7713	43.135.130.202	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	United States	Santa Clara	California	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	Direct	/forgot_password	2026-05-09 21:24:36.791338	2026-05-09 21:24:36.791338	1	1	f	\N	2026-05-09 21:24:36.791338
182	b0a887f9-d753-4092-8e3f-c1fcae19e845	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 21:25:05.87825	2026-05-09 21:25:05.87825	1	1	f	\N	2026-05-09 21:25:05.87825
183	67e2e015-763c-4e77-abe3-76ff441ca003	31.57.38.139	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.129 Safari/537.36	United States	Edison	New Jersey	Chrome 81.0.4044	Linux 	Desktop	Direct	/.env	2026-05-09 21:28:48.027673	2026-05-09 21:28:48.027673	1	1	f	\N	2026-05-09 21:28:48.027673
184	c174faf9-b8fa-4771-a3a5-3a980ce6574b	31.57.38.139	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.129 Safari/537.36	United States	Edison	New Jersey	Chrome 81.0.4044	Linux 	Desktop	Direct	/	2026-05-09 21:28:49.813243	2026-05-09 21:28:49.813243	1	1	f	\N	2026-05-09 21:28:49.813243
185	4f01d8f7-cce8-4248-ad44-d6bc402c2e51	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 21:34:41.363604	2026-05-09 21:34:41.363604	1	1	f	\N	2026-05-09 21:34:41.363604
186	e1d18f1a-a0e2-4454-af89-e487b21ea54b	103.190.47.118	Mozilla/5.0 (Macintosh; Intel Mac OS X 14_1_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.6668.58 Safari/537.36	Indonesia	Denpasar	Bali	Chrome 129.0.6668	Mac OS X 14.1.0	Desktop	Direct	/robots.txt	2026-05-09 21:36:43.491094	2026-05-09 21:36:43.491094	1	1	f	\N	2026-05-09 21:36:43.491094
187	d14bd570-aaa3-48fc-a188-bb60d2135f1f	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 21:49:28.545892	2026-05-09 21:49:28.545892	1	1	f	\N	2026-05-09 21:49:28.545892
188	d2342932-59a8-4410-9571-44d1b8f53cae	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 21:59:01.507675	2026-05-09 21:59:01.507675	1	1	f	\N	2026-05-09 21:59:01.507675
189	4e0ab285-72dc-45c3-998b-7e57264afd62	205.210.31.13	Hello from Palo Alto Networks, find out more about our scans in https://docs-cortex.paloaltonetworks.com/r/1/Cortex-Xpanse/Scanning-activity	United States	Santa Clara	California	Other 	Other 	Desktop	Direct	/	2026-05-09 21:59:33.715778	2026-05-09 21:59:33.715778	1	1	f	\N	2026-05-09 21:59:33.715778
190	a724e88a-69e6-4acf-b2f4-a9a40a5333f7	223.109.255.167	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	China	Nanjing	Jiangsu	Chrome 144.0.0	Windows 10	Desktop	Direct	/online/best-casino-in-japan-apk-24575t48.pdf	2026-05-09 22:07:10.15646	2026-05-09 22:07:10.15646	1	1	f	\N	2026-05-09 22:07:10.15646
191	d1fedb13-a341-49a0-bd68-b20668ad4268	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 22:08:39.718867	2026-05-09 22:08:39.718867	1	1	f	\N	2026-05-09 22:08:39.718867
192	09ec7c4d-d7da-4c44-b216-84221d83f03d	192.154.102.34		United States	Salt Lake City	Utah	Other 	Other 	Desktop	Direct	/	2026-05-09 22:08:56.718136	2026-05-09 22:08:56.718136	1	1	f	\N	2026-05-09 22:08:56.718136
193	f03b9cf0-17e0-4b3a-9767-4e6fe693616e	94.23.188.212	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	France	Roubaix	Hauts-de-France	AhrefsBot 7.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-09 22:16:03.384058	2026-05-09 22:16:03.384058	1	1	f	\N	2026-05-09 22:16:03.384058
194	2952380c-44d2-4ca6-9e18-145ed6724be6	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 22:19:14.656865	2026-05-09 22:19:14.656865	1	1	f	\N	2026-05-09 22:19:14.656865
195	82e1169f-8eec-481c-9347-7cc4dfeee466	216.73.216.13	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)	United States	Columbus	Ohio	ClaudeBot 1.0	Other 	Desktop	Direct	/robots.txt	2026-05-09 22:24:35.941918	2026-05-09 22:24:35.941918	1	1	f	\N	2026-05-09 22:24:35.941918
196	faa57d67-f76c-48ef-9f4f-61e77ca127b7	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 22:25:44.164967	2026-05-09 22:25:44.164967	1	1	f	\N	2026-05-09 22:25:44.164967
197	c243002a-54ba-4d17-936f-dd711a0f242c	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 22:35:25.644621	2026-05-09 22:35:25.644621	1	1	f	\N	2026-05-09 22:35:25.644621
198	6c08eacc-bce3-4819-be17-e1e3f89d8d95	43.129.169.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36	Hong Kong	Hong Kong	\N	Chrome 106.0.0	Windows 10	Desktop	Direct	/Core/Skin/Login.aspx	2026-05-09 22:40:04.649002	2026-05-09 22:40:04.649002	1	1	f	\N	2026-05-09 22:40:04.649002
199	636f7de6-972d-4dd5-8337-f168c1e16ce2	98.88.179.76	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/600.2.5 (KHTML, like Gecko) Version/8.0.2 Safari/600.2.5 (Gort)	United States	Ashburn	Virginia	Safari 8.0.2	Mac OS X 10.10.1	Desktop	Direct	/robots.txt	2026-05-09 22:42:28.961438	2026-05-09 22:42:28.961438	1	1	f	\N	2026-05-09 22:42:28.961438
200	b0513bfb-3327-42fc-8b89-05ac04dfca1c	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 22:43:34.099882	2026-05-09 22:43:34.099882	1	1	f	\N	2026-05-09 22:43:34.099882
201	dbd25cae-e8c5-48d2-ae82-d165f1a7ddf4	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	United States	Columbus	Ohio	Claude-SearchBot 1.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-09 22:53:20.592819	2026-05-09 22:53:20.592819	1	1	f	\N	2026-05-09 22:53:20.592819
202	89991a33-e30f-410e-8902-ccb6e770ff44	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 22:54:42.161738	2026-05-09 22:54:42.161738	1	1	f	\N	2026-05-09 22:54:42.161738
203	edf7da4f-716a-4c64-ad68-01e21da6fcd2	216.73.160.46	Mozilla/5.0	United States	New York	New York	Other 	Other 	Desktop	Direct	/wp-login.php	2026-05-09 22:57:30.925814	2026-05-09 22:57:30.925814	1	1	f	\N	2026-05-09 22:57:30.925814
204	2a127c07-3281-44ee-b736-730305b5efcf	112.86.225.21	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	China	Suzhou	Jiangsu	Chrome 144.0.0	Windows 10	Desktop	Direct	/online/badminton-olympic-india-apk-25701t6.pdf	2026-05-09 23:06:29.810325	2026-05-09 23:06:29.810325	1	1	f	\N	2026-05-09 23:06:29.810325
205	09f15177-b280-44a2-94de-1826596d0e3d	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 23:09:41.751952	2026-05-09 23:09:41.751952	1	1	f	\N	2026-05-09 23:09:41.751952
206	677926a1-5545-4d9a-a35e-0d9233d26e03	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-09 23:19:37.432727	2026-05-09 23:19:37.432727	1	1	f	\N	2026-05-09 23:19:37.432727
207	4944aab0-73eb-4586-9ffc-00cc499ed544	94.176.54.57	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:150.0) Gecko/20100101 Firefox/150.0	United States	New York City	New York	Firefox 150.0	Windows 10	Desktop	https://gspaces.in/	/	2026-05-09 23:19:53.371969	2026-05-09 23:19:53.371969	1	1	f	\N	2026-05-09 23:19:53.371969
208	6c3423fe-d093-411d-8d20-b56031f5dd56	162.243.212.67	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	United States	Secaucus	New Jersey	Chrome 146.0.0	Windows 10	Desktop	Direct	/	2026-05-09 23:19:53.377735	2026-05-09 23:19:53.377735	1	1	f	\N	2026-05-09 23:19:53.377735
209	5c911659-4b0f-49d3-9cbd-075f588a2263	206.204.50.44	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15	United States	New York City	New York	Safari 26.0	Mac OS X 10.15.7	Desktop	https://gspaces.in/	/	2026-05-09 23:19:53.379384	2026-05-09 23:19:53.379384	1	1	f	\N	2026-05-09 23:19:53.379384
210	95251b02-ffb0-4175-9256-71a35fb9cb1a	159.203.88.57	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15	United States	Clifton	New Jersey	Safari 26.0	Mac OS X 10.15.7	Desktop	https://gspaces.in/	/	2026-05-09 23:19:53.381271	2026-05-09 23:19:53.381271	1	1	f	\N	2026-05-09 23:19:53.381271
211	1db50ade-624a-41b1-8794-26017684ce5a	157.245.220.98	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:150.0) Gecko/20100101 Firefox/150.0	Unknown	Unknown	Unknown	Firefox 150.0	Windows 10	Desktop	https://gspaces.in/	/	2026-05-09 23:19:53.501773	2026-05-09 23:19:53.501773	1	1	f	\N	2026-05-09 23:19:53.501773
212	309779ad-41bb-489f-80df-0efa9c865171	99.20.133.102	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	Unknown	Unknown	Unknown	Edge 147.0.0	Windows 10	Desktop	https://www.google.com/	/	2026-05-09 23:19:53.527691	2026-05-09 23:19:53.527691	1	1	f	\N	2026-05-09 23:19:53.527691
213	84f3d7ec-bcc2-47c9-9c6d-c67bebe96df1	213.188.78.130	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 146.0.0	Windows 10	Desktop	Direct	/	2026-05-09 23:19:53.52916	2026-05-09 23:19:53.52916	1	1	f	\N	2026-05-09 23:19:53.52916
214	459a78bd-37d6-4878-b7ba-5ce77b40ae58	45.76.165.95	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 147.0.0	Windows 10	Desktop	Direct	/	2026-05-09 23:19:53.530122	2026-05-09 23:19:53.530122	1	1	f	\N	2026-05-09 23:19:53.530122
215	b2b4ea0f-177d-4ae0-83fa-75674db3d8ef	173.168.78.74	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 147.0.0	Windows 10	Desktop	Direct	/	2026-05-09 23:19:53.668091	2026-05-09 23:19:53.668091	1	1	f	\N	2026-05-09 23:19:53.668091
216	62f7cd07-0eb4-4973-8259-a4457b4a8e4f	129.222.143.94	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 146.0.0	Windows 10	Desktop	Direct	/	2026-05-09 23:19:53.670842	2026-05-09 23:19:53.670842	1	1	f	\N	2026-05-09 23:19:53.670842
217	f320934b-6bc3-440e-b200-20b5f0eed2e9	161.123.78.103	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 147.0.0	Windows 10	Desktop	Direct	/	2026-05-09 23:19:53.681136	2026-05-09 23:19:53.681136	1	1	f	\N	2026-05-09 23:19:53.681136
218	c47ff837-64aa-4785-b1da-1f6a73a716ff	67.248.87.82	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:150.0) Gecko/20100101 Firefox/150.0	Unknown	Unknown	Unknown	Firefox 150.0	Windows 10	Desktop	https://gspaces.in/	/	2026-05-09 23:19:53.687522	2026-05-09 23:19:53.687522	1	1	f	\N	2026-05-09 23:19:53.687522
219	d32c28e8-8a52-493d-8b8b-af103784e06f	24.151.161.223	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15	Unknown	Unknown	Unknown	Safari 26.0	Mac OS X 10.15.7	Desktop	https://gspaces.in/	/	2026-05-09 23:19:53.793414	2026-05-09 23:19:53.793414	1	1	f	\N	2026-05-09 23:19:53.793414
220	884915a7-aa3f-480d-a719-98d2dbeaecc1	176.223.106.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0	Unknown	Unknown	Unknown	Edge 147.0.0	Windows 10	Desktop	https://www.google.com/	/	2026-05-09 23:19:53.797913	2026-05-09 23:19:53.797913	1	1	f	\N	2026-05-09 23:19:53.797913
221	67c8373b-6dc4-4563-bd13-a15de66e9b14	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 23:28:16.847011	2026-05-09 23:28:16.847011	1	1	f	\N	2026-05-09 23:28:16.847011
222	20b6e6c1-b478-4bc4-8c32-ec9fc39f9877	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 23:38:19.665701	2026-05-09 23:38:19.665701	1	1	f	\N	2026-05-09 23:38:19.665701
223	857c9460-b333-4e47-91a6-e74e07a35481	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 23:45:02.847879	2026-05-09 23:45:02.847879	1	1	f	\N	2026-05-09 23:45:02.847879
224	906b59ab-cb00-4e31-8a1e-848a767631d1	92.222.108.120	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	Unknown	Unknown	Unknown	AhrefsBot 7.0	Other 	Desktop	Direct	/robots.txt	2026-05-09 23:48:26.242323	2026-05-09 23:48:26.242323	1	1	f	\N	2026-05-09 23:48:26.242323
225	cbf108fc-8f72-4cc1-97c0-98bd5bdc4ac0	92.222.108.113	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	Unknown	Unknown	Unknown	AhrefsBot 7.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-09 23:48:27.626336	2026-05-09 23:48:27.626336	1	1	f	\N	2026-05-09 23:48:27.626336
226	3fafde58-1311-4609-8514-9f25e470fc55	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-09 23:54:51.262966	2026-05-09 23:54:51.262966	1	1	f	\N	2026-05-09 23:54:51.262966
227	dd2ebb44-3408-4b0d-bc8b-646dfcb24aec	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 00:01:52.775759	2026-05-10 00:01:52.775759	1	1	f	\N	2026-05-10 00:01:52.775759
228	7e8b20b1-5215-4f7c-95a3-2c351703a055	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 00:14:24.385132	2026-05-10 00:14:24.385132	1	1	f	\N	2026-05-10 00:14:24.385132
229	a8424117-647a-42d9-933e-c536ad9810fd	43.129.169.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 106.0.0	Windows 10	Desktop	Direct	/Core/Skin/Login.aspx	2026-05-10 00:18:26.655935	2026-05-10 00:18:26.655935	1	1	f	\N	2026-05-10 00:18:26.655935
230	96ce8e1b-6df9-4253-9686-c26e6cb7262f	2a03:2880:f806:21::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	Unknown	Unknown	Unknown	meta-webindexer 1.1	Other 	Desktop	Direct	/product/10	2026-05-10 00:18:27.578935	2026-05-10 00:18:27.578935	1	1	f	\N	2026-05-10 00:18:27.578935
231	ed5adbb1-c218-4f11-be2e-b7d1aa595f32	2a03:2880:f806:1::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	United States	Atlanta	Georgia	meta-webindexer 1.1	Other 	Desktop	Direct	/about	2026-05-10 00:23:17.670957	2026-05-10 00:23:17.670957	1	1	f	\N	2026-05-10 00:23:17.670957
232	87beabf3-f5b6-4be6-91fe-3529d5e5ac2e	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 00:26:42.525894	2026-05-10 00:26:42.525894	1	1	f	\N	2026-05-10 00:26:42.525894
233	f78c3204-49f3-4d82-b926-4e6c8109cc3b	161.0.60.2	Mozilla/5.0 (X11; Ubuntu; Linux x86_64; arm64) AppleWebKit/537.36 (KHTML, like Gecko) Opera/73.0.0.0 Safari/537.36	Nicaragua	Managua	Managua Department	Opera 73.0.0	Ubuntu 	Desktop	Direct	/xmlrpc.php	2026-05-10 00:33:42.330317	2026-05-10 00:33:42.330317	1	1	f	\N	2026-05-10 00:33:42.330317
234	62a22507-ffe3-4c13-85c5-1b55e1529f88	216.73.216.13	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)	United States	Columbus	Ohio	ClaudeBot 1.0	Other 	Desktop	Direct	/robots.txt	2026-05-10 00:34:07.401966	2026-05-10 00:34:07.401966	1	1	f	\N	2026-05-10 00:34:07.401966
235	b404cb35-c682-43a7-be0e-39804521a4ad	167.172.187.227	Mozilla/5.0 (X11; Linux x86_64; rv:142.0) Gecko/20100101 Firefox/142.0	Germany	Frankfurt am Main	Hesse	Firefox 142.0	Linux 	Desktop	Direct	/	2026-05-10 00:36:06.807155	2026-05-10 00:36:06.807155	1	1	f	\N	2026-05-10 00:36:06.807155
236	b0ff7765-2c90-4752-8776-32920b73d500	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 00:38:47.169948	2026-05-10 00:38:47.169948	1	1	f	\N	2026-05-10 00:38:47.169948
237	555f9dd8-f1eb-41a5-bbcf-6faa4806df19	46.202.224.81	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	United States	Ashburn	Virginia	Chrome 116.0.5845	Windows 10	Desktop	Direct	/.env	2026-05-10 00:46:50.724331	2026-05-10 00:46:50.724331	1	1	f	\N	2026-05-10 00:46:50.724331
238	3fe4fba7-3cc1-4862-b14b-d67afdb133a3	46.202.224.81	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	United States	Ashburn	Virginia	Chrome 116.0.5845	Windows 10	Desktop	Direct	/	2026-05-10 00:46:51.761102	2026-05-10 00:46:51.761102	1	1	f	\N	2026-05-10 00:46:51.761102
239	9e44bb69-738f-4f86-88db-52bf38614185	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 00:48:11.471768	2026-05-10 00:48:11.471768	1	1	f	\N	2026-05-10 00:48:11.471768
277	f6683760-c662-4146-ba63-f44a4b00ff5e	154.29.232.248	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	Unknown	Unknown	Unknown	Chrome 116.0.5845	Windows 10	Desktop	Direct	/	2026-05-10 02:31:05.328053	2026-05-10 02:31:05.328053	1	1	f	\N	2026-05-10 02:31:05.328053
240	ebea27b8-3987-4354-8791-5a80387acf8c	145.239.71.235	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	France	Roubaix	Hauts-de-France	Chrome 142.0.0	Windows 10	Desktop	Direct	/	2026-05-10 00:49:09.865129	2026-05-10 00:49:13.712222	2	2	f	\N	2026-05-10 00:49:09.865129
241	1ac1da20-eae1-4014-85cb-b805e6a78b71	172.98.33.248	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.6167.85 Safari/537.36	United States	Dallas	Texas	Chrome 121.0.6167	Windows 10	Desktop	Direct	/wp-login.php	2026-05-10 00:53:16.99479	2026-05-10 00:53:16.99479	1	1	f	\N	2026-05-10 00:53:16.99479
242	07237918-766c-4f89-9ab5-62d9e047e9ff	136.144.43.211	Mozilla/5.0 (Windows NT 11.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.6167.85 Safari/537.36	United States	Dallas	Texas	Chrome 121.0.6167	Windows NT	Desktop	Direct	/administrator/	2026-05-10 00:53:17.852032	2026-05-10 00:53:17.852032	1	1	f	\N	2026-05-10 00:53:17.852032
243	0d44eb87-94e0-45a0-877e-77a0ba952dd1	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 00:54:55.481786	2026-05-10 00:54:55.481786	1	1	f	\N	2026-05-10 00:54:55.481786
244	03bdc66e-9917-4d82-8d94-03230805b44e	145.239.71.235	Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0	France	Roubaix	Hauts-de-France	Firefox 140.0	Linux 	Desktop	Direct	/	2026-05-10 00:59:49.568603	2026-05-10 00:59:53.476315	2	2	f	\N	2026-05-10 00:59:49.568603
245	bd13d47b-0e69-4879-ae4a-ca69c4ef0ff9	66.228.53.46	Mozilla/5.0 (Macintosh; Intel Mac OS X 13_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36	United States	Richardson	Texas	Chrome 108.0.0	Mac OS X 13.1	Desktop	Direct	/	2026-05-10 00:59:57.590866	2026-05-10 00:59:57.590866	1	1	f	\N	2026-05-10 00:59:57.590866
246	b3e8fa31-d2b1-4ae7-a75b-35540438d69d	74.125.216.7	Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.7727.137 Mobile Safari/537.36 (compatible; AdsBot-Google-Mobile; +http://www.google.com/mobile/adsbot.html)	United States	Mountain View	California	AdsBot-Google 	Android 6.0.1	Mobile	Direct	/.well-known/apple-app-site-association	2026-05-10 01:01:56.318619	2026-05-10 01:01:56.318619	1	1	f	\N	2026-05-10 01:01:56.318619
247	0d43db73-cee9-42e3-b7e6-ffd5de04db48	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 01:03:47.458676	2026-05-10 01:03:47.458676	1	1	f	\N	2026-05-10 01:03:47.458676
248	2dd73caf-3f13-4504-bd4d-899027abbb09	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	United States	Columbus	Ohio	Claude-SearchBot 1.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-10 01:06:20.498065	2026-05-10 01:06:20.498065	1	1	f	\N	2026-05-10 01:06:20.498065
249	3fdd55d6-796c-42e5-b84b-543923fed79a	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 01:13:09.221571	2026-05-10 01:13:09.221571	1	1	f	\N	2026-05-10 01:13:09.221571
250	9f0db4a5-e445-4b61-83ff-95a14e357628	118.194.228.167	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0	Japan	Tokyo	Tokyo	Edge 120.0.0	Mac OS X 10.15.7	Desktop	Direct	/	2026-05-10 01:18:18.821404	2026-05-10 01:18:18.821404	1	1	f	\N	2026-05-10 01:18:18.821404
251	504f76e1-cf18-4cff-ab78-597bdd584f21	118.194.228.167	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0	Japan	Tokyo	Tokyo	Edge 120.0.0	Mac OS X 10.15.7	Desktop	Direct	/robots.txt	2026-05-10 01:18:38.790264	2026-05-10 01:18:38.790264	1	1	f	\N	2026-05-10 01:18:38.790264
252	51e75f13-ab07-496a-8e8f-04ca118dfec4	118.194.228.167	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0	Japan	Tokyo	Tokyo	Edge 120.0.0	Mac OS X 10.15.7	Desktop	Direct	/sitemap.xml	2026-05-10 01:18:39.35362	2026-05-10 01:18:39.35362	1	1	f	\N	2026-05-10 01:18:39.35362
253	9eddf26a-bcb9-42ba-84a8-a2157c169181	118.194.228.167	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.56 Safari/535.11	Japan	Tokyo	Tokyo	Chrome 17.0.963	Mac OS X 10.7.0	Desktop	Direct	/config.json	2026-05-10 01:18:41.884174	2026-05-10 01:18:41.884174	1	1	f	\N	2026-05-10 01:18:41.884174
254	cd577a1e-f7c5-42c7-a085-441d21832727	94.23.188.219	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	France	Roubaix	Hauts-de-France	AhrefsBot 7.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-10 01:18:44.283365	2026-05-10 01:18:44.283365	1	1	f	\N	2026-05-10 01:18:44.283365
255	7bbdffa3-240c-4cb7-a5a2-ccba9f33a598	103.151.226.38	Hello, World	Indonesia	Margahayukencana	West Java	Other 	Other 	Desktop	Direct	/GponForm/diag_Form	2026-05-10 01:21:28.196587	2026-05-10 01:21:28.196587	1	1	f	\N	2026-05-10 01:21:28.196587
256	36857180-3cf4-4e23-86e2-4770d38ebbcd	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 01:21:56.308227	2026-05-10 01:21:56.308227	1	1	f	\N	2026-05-10 01:21:56.308227
257	717427c7-649f-4f59-aadb-fc5d99e96a51	167.99.149.55	Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/118.0	United States	North Bergen	New Jersey	Firefox 118.0	Windows 10	Desktop	Direct	/	2026-05-10 01:26:10.56153	2026-05-10 01:26:10.56153	1	1	f	\N	2026-05-10 01:26:10.56153
258	2b9185a3-464c-497d-8a83-6d500f1eec0c	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 01:32:52.898173	2026-05-10 01:32:52.898173	1	1	f	\N	2026-05-10 01:32:52.898173
259	f4cb137d-5cd3-436e-a4de-c430a1739587	2a03:2880:f806:1e::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	United States	Atlanta	Georgia	meta-webindexer 1.1	Other 	Desktop	Direct	/product/25	2026-05-10 01:38:36.56748	2026-05-10 01:38:36.56748	1	1	f	\N	2026-05-10 01:38:36.56748
260	702f4b7c-26f7-4e7e-a7cf-7c8916b6ce92	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 01:48:29.640972	2026-05-10 01:48:29.640972	1	1	f	\N	2026-05-10 01:48:29.640972
261	c38d9733-0114-4b97-9c1c-140fb3be9a18	74.125.216.6	Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.7727.137 Mobile Safari/537.36 (compatible; AdsBot-Google-Mobile; +http://www.google.com/mobile/adsbot.html)	United States	Mountain View	California	AdsBot-Google 	Android 6.0.1	Mobile	Direct	/apple-app-site-association	2026-05-10 01:53:04.459199	2026-05-10 01:53:04.459199	1	1	f	\N	2026-05-10 01:53:04.459199
262	9ada0c09-0f02-4670-af59-2ff9f3ce72c3	47.254.84.190	curl/7.64.1	United States	Minkler	California	curl 7.64.1	Other 	Desktop	Direct	/	2026-05-10 01:56:10.476742	2026-05-10 01:56:10.476742	1	1	f	\N	2026-05-10 01:56:10.476742
263	66e1d694-a7f3-420c-92cb-0569b2bc8c86	47.254.84.190	curl/7.74.0	United States	Minkler	California	curl 7.74.0	Other 	Desktop	Direct	/	2026-05-10 01:56:11.341815	2026-05-10 01:56:11.341815	1	1	f	\N	2026-05-10 01:56:11.341815
264	ad16cd93-88d5-4a69-b1c7-fe96b5898eaa	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 01:57:06.067764	2026-05-10 01:57:06.067764	1	1	f	\N	2026-05-10 01:57:06.067764
265	6f277864-8e81-43a6-bed6-65cb91f9fb39	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 02:06:41.923609	2026-05-10 02:06:41.923609	1	1	f	\N	2026-05-10 02:06:41.923609
266	56dec003-5219-4785-810f-9b982c9b9a0b	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 02:17:02.693641	2026-05-10 02:17:02.693641	1	1	f	\N	2026-05-10 02:17:02.693641
267	90041d89-1e3f-481e-a1c9-b69dd4433b41	2a03:2880:f806:3e::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	United States	Atlanta	Georgia	meta-webindexer 1.1	Other 	Desktop	Direct	/product/9	2026-05-10 02:21:56.189086	2026-05-10 02:21:56.189086	1	1	f	\N	2026-05-10 02:21:56.189086
268	a13f396d-ef90-47e8-a0d3-9c24f7064dc4	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 02:22:28.741753	2026-05-10 02:22:28.741753	1	1	f	\N	2026-05-10 02:22:28.741753
269	a0bc56b1-9fcd-4ee0-ad45-52f1e8a9e756	43.135.182.43	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	United States	Santa Clara	California	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	http://www.gspaces.in	/	2026-05-10 02:22:31.440952	2026-05-10 02:22:31.440952	1	1	f	\N	2026-05-10 02:22:31.440952
270	e0263c2e-90d5-4ccc-ae32-65be286e0778	43.135.130.202	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	United States	Santa Clara	California	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	Direct	/	2026-05-10 02:23:36.783166	2026-05-10 02:23:36.783166	1	1	f	\N	2026-05-10 02:23:36.783166
271	6e463cde-1945-45ed-990f-7376efee51b6	167.250.224.25	xfa1	Brazil	Campo Maior	Piauí	Other 	Other 	Desktop	Direct	/admin/config.php	2026-05-10 02:23:46.946718	2026-05-10 02:23:46.946718	1	1	f	\N	2026-05-10 02:23:46.946718
351	sample_visitor_2	192.168.1.2	\N	USA	New York	\N	Safari	iOS	mobile	\N	\N	2026-05-10 06:32:24.175695	2026-05-10 06:32:24.175695	1	1	f	\N	2026-05-10 06:32:24.175695
272	993ec7b1-3d9c-4fbd-9958-3bb1714383ab	2a03:2880:f806:f::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	United States	Atlanta	Georgia	meta-webindexer 1.1	Other 	Desktop	Direct	/signup	2026-05-10 02:27:46.751243	2026-05-10 02:27:46.751243	1	1	f	\N	2026-05-10 02:27:46.751243
273	bf58d6bc-36e6-42d0-8964-950e56019a12	216.73.216.13	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)	United States	Columbus	Ohio	ClaudeBot 1.0	Other 	Desktop	Direct	/robots.txt	2026-05-10 02:28:33.845407	2026-05-10 02:28:33.845407	1	1	f	\N	2026-05-10 02:28:33.845407
275	57a7945c-9581-444c-b4a3-464cd45b6e07	52.236.68.31		Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/wp-content/plugins/hellopress/wp_filemanager.php	2026-05-10 02:29:09.070642	2026-05-10 02:29:18.896814	52	52	f	\N	2026-05-10 02:29:09.070642
278	1702dbad-1384-4101-b040-d4c8aabfc046	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 02:33:39.88759	2026-05-10 02:33:39.88759	1	1	f	\N	2026-05-10 02:33:39.88759
279	8995e4e9-4d4a-4024-a010-716bf1e937ef	43.157.52.37	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Unknown	Unknown	Unknown	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	Direct	/my-workspace	2026-05-10 02:38:31.416353	2026-05-10 02:38:31.416353	1	1	f	\N	2026-05-10 02:38:31.416353
280	75a7c5e9-2a66-4941-9fc6-310bf6a97610	43.157.52.37	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Unknown	Unknown	Unknown	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	http://3.7.69.151/my-workspace	/login	2026-05-10 02:38:32.551129	2026-05-10 02:38:32.551129	1	1	f	\N	2026-05-10 02:38:32.551129
282	003d5138-6502-476e-994e-38035c3b8761	37.59.204.145	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	Unknown	Unknown	Unknown	AhrefsBot 7.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-10 02:42:43.821682	2026-05-10 02:42:43.821682	1	1	f	\N	2026-05-10 02:42:43.821682
283	64e7a60a-0171-4e69-b96f-177c5c961d1c	43.155.27.244	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Unknown	Unknown	Unknown	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	Direct	/my-workspace	2026-05-10 02:45:53.132727	2026-05-10 02:45:53.132727	1	1	f	\N	2026-05-10 02:45:53.132727
284	ace3575a-acbe-401f-9934-c5e400526fb6	43.155.27.244	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Unknown	Unknown	Unknown	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	https://www.gspaces.in/my-workspace	/login	2026-05-10 02:45:54.783537	2026-05-10 02:45:54.783537	1	1	f	\N	2026-05-10 02:45:54.783537
285	31c318b7-5f1f-49ba-8f9d-d18ede4cb26e	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 02:49:59.86085	2026-05-10 02:49:59.86085	1	1	f	\N	2026-05-10 02:49:59.86085
286	defe5b06-d2ca-470c-ada7-9f3ddcb5cb37	43.166.244.66	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Unknown	Unknown	Unknown	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	Direct	/signup	2026-05-10 02:54:49.573983	2026-05-10 02:54:49.573983	1	1	f	\N	2026-05-10 02:54:49.573983
287	d5644296-f36d-4d55-be24-caf26c941647	2a03:2880:f806:40::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	Unknown	Unknown	Unknown	meta-webindexer 1.1	Other 	Desktop	Direct	/product/21	2026-05-10 02:56:38.943333	2026-05-10 02:56:38.943333	1	1	f	\N	2026-05-10 02:56:38.943333
288	78b455e6-ed3f-420d-a94d-30e2103bff74	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 03:05:04.037798	2026-05-10 03:05:04.037798	1	1	f	\N	2026-05-10 03:05:04.037798
289	5f92c8a9-0ae6-4377-9550-a5591a16dca7	43.157.46.118	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Unknown	Unknown	Unknown	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	Direct	/forgot_password	2026-05-10 03:05:06.757187	2026-05-10 03:05:06.757187	1	1	f	\N	2026-05-10 03:05:06.757187
290	2b43a61b-a1e1-4962-bf2b-49dda6993661	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 03:13:28.864975	2026-05-10 03:13:28.864975	1	1	f	\N	2026-05-10 03:13:28.864975
291	58756048-7bc7-4cb9-9f75-ec07d062e00a	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	Unknown	Unknown	Unknown	Claude-SearchBot 1.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-10 03:15:36.36919	2026-05-10 03:15:36.36919	1	1	f	\N	2026-05-10 03:15:36.36919
292	a9bc1656-d64e-47dc-a4aa-dbc6afc9c7cc	43.153.26.165	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Unknown	Unknown	Unknown	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	Direct	/login	2026-05-10 03:16:07.88855	2026-05-10 03:16:07.88855	1	1	f	\N	2026-05-10 03:16:07.88855
293	25b80d9a-972e-42cc-95bf-21e45f46407b	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 03:24:08.704233	2026-05-10 03:24:08.704233	1	1	f	\N	2026-05-10 03:24:08.704233
294	9122c59f-6668-4817-a099-8e8065ce626e	185.192.71.45	Go-http-client/2.0	United Kingdom	London	England	Go-http-client 2.0	Other 	Desktop	Direct	/txets.php	2026-05-10 03:28:44.656882	2026-05-10 03:28:44.656882	1	1	f	\N	2026-05-10 03:28:44.656882
295	c2f740d5-ded7-45c6-afc1-37ad006e2878	185.192.71.45	Go-http-client/2.0	United Kingdom	London	England	Go-http-client 2.0	Other 	Desktop	Direct	/wp-content/txets.php	2026-05-10 03:28:45.229003	2026-05-10 03:28:45.229003	1	1	f	\N	2026-05-10 03:28:45.229003
296	a1dd2631-5b99-49f7-b13f-b8367da03e21	185.192.71.45	Go-http-client/2.0	United Kingdom	London	England	Go-http-client 2.0	Other 	Desktop	Direct	/wp-admin/txets.php	2026-05-10 03:28:45.657377	2026-05-10 03:28:45.657377	1	1	f	\N	2026-05-10 03:28:45.657377
274	3980b12b-7cfb-431e-bc72-935680390502	20.123.33.13		Ireland	Dublin	Leinster	Other 	Other 	Desktop	Direct	/wp-content/plugins/hellopress/wp_filemanager.php	2026-05-10 02:28:34.452154	2026-05-10 02:28:43.714368	52	52	f	\N	2026-05-10 02:28:34.452154
297	bc66a6a5-a3c6-4d6b-8522-6c23dd8d0a83	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 03:31:44.117808	2026-05-10 03:31:44.117808	1	1	f	\N	2026-05-10 03:31:44.117808
298	d6bb76dd-78cd-47ec-9622-50e5386d4cce	43.129.169.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36	Hong Kong	Hong Kong	\N	Chrome 106.0.0	Windows 10	Desktop	Direct	/Core/Skin/Login.aspx	2026-05-10 03:35:07.206151	2026-05-10 03:35:07.206151	1	1	f	\N	2026-05-10 03:35:07.206151
299	409ef56d-eb95-4db0-bfeb-fa7a123044ae	174.79.247.143	Mozilla/5.0 (Macintosh; Intel Mac OS X 11_7_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.6668.29 Safari/537.36	United States	San Diego	California	Chrome 129.0.6668	Mac OS X 11.7.0	Desktop	Direct	/robots.txt	2026-05-10 03:38:22.532771	2026-05-10 03:38:22.532771	1	1	f	\N	2026-05-10 03:38:22.532771
300	8c9b87f8-b79b-4923-9d63-5146d78562ed	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 03:43:22.517433	2026-05-10 03:43:22.517433	1	1	f	\N	2026-05-10 03:43:22.517433
301	5714e44e-b778-4b0f-9e09-960999855a94	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 03:48:11.366419	2026-05-10 03:48:11.366419	1	1	f	\N	2026-05-10 03:48:11.366419
302	1f44da4d-9374-442c-9d1b-26437a6399ff	2001:4ca0:108:42::24	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.134 Safari/537.36	Germany	Munich	Bavaria	Chrome 103.0.5060	Windows 10	Desktop	Direct	/robots.txt	2026-05-10 03:58:27.252289	2026-05-10 03:58:27.252289	1	1	f	\N	2026-05-10 03:58:27.252289
303	359569aa-118b-4679-9d06-70e0004c657b	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 03:58:34.459979	2026-05-10 03:58:34.459979	1	1	f	\N	2026-05-10 03:58:34.459979
304	217c6222-86ec-4a2b-83a0-5515a80042b7	194.132.63.30	Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.3	Germany	Frankfurt am Main	Hesse	Chrome 121.0.0	Chrome OS 14541.0.0	Desktop	http://www.gspaces.in/	/	2026-05-10 04:04:04.759245	2026-05-10 04:04:04.759245	1	1	f	\N	2026-05-10 04:04:04.759245
305	bd6f56e8-9b8a-4eb3-a3b2-e24a6d2cc3ec	37.59.204.145	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	Belgium	Zaventem	Flanders	AhrefsBot 7.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-10 04:06:19.402955	2026-05-10 04:06:19.402955	1	1	f	\N	2026-05-10 04:06:19.402955
306	17ef1f37-9016-44d4-bc22-246518b11dfc	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 04:10:22.331149	2026-05-10 04:10:22.331149	1	1	f	\N	2026-05-10 04:10:22.331149
307	d47dfb14-bec1-44dc-bc56-36da6b570d46	82.21.244.235	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	South Africa	Johannesburg	Gauteng	Chrome 116.0.5845	Windows 10	Desktop	Direct	/.env	2026-05-10 04:13:01.680729	2026-05-10 04:13:01.680729	1	1	f	\N	2026-05-10 04:13:01.680729
308	38b90a8a-2ee0-433b-bcb0-00e8dc49cca3	82.21.244.235	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	South Africa	Johannesburg	Gauteng	Chrome 116.0.5845	Windows 10	Desktop	Direct	/	2026-05-10 04:13:02.99933	2026-05-10 04:13:02.99933	1	1	f	\N	2026-05-10 04:13:02.99933
309	2f7c03b2-50ff-4a61-a270-97c0d13abe85	175.178.110.121	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	China	Guangzhou	Guangdong	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	http://www.gspaces.in	/	2026-05-10 04:14:40.960042	2026-05-10 04:14:40.960042	1	1	f	\N	2026-05-10 04:14:40.960042
310	617bc9ea-2dfc-43ac-ab75-40f9301677a6	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 04:22:50.433933	2026-05-10 04:22:50.433933	1	1	f	\N	2026-05-10 04:22:50.433933
311	01bad875-f33a-43b5-8ff6-3211f6dd881e	216.73.216.13	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; ClaudeBot/1.0; +claudebot@anthropic.com)	United States	Columbus	Ohio	ClaudeBot 1.0	Other 	Desktop	Direct	/robots.txt	2026-05-10 04:31:19.021756	2026-05-10 04:31:19.021756	1	1	f	\N	2026-05-10 04:31:19.021756
312	2b4f9d4d-27b1-4750-a688-a2833fd4349b	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 04:32:18.83696	2026-05-10 04:32:18.83696	1	1	f	\N	2026-05-10 04:32:18.83696
313	226ee813-d6b4-45a0-99a5-ec892be142c2	20.207.201.147	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36	India	Pune	Maharashtra	Chrome 123.0.0	Windows 10	Desktop	http://gspaces.in	/	2026-05-10 04:38:43.618106	2026-05-10 04:38:43.618106	1	1	f	\N	2026-05-10 04:38:43.618106
314	278c34a0-cf8e-45aa-828c-0739fb5c5fdf	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 04:42:02.63814	2026-05-10 04:42:02.63814	1	1	f	\N	2026-05-10 04:42:02.63814
315	a28c82b2-7406-4199-8d44-05f0b950b9b3	43.163.206.70	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Japan	Tokyo	Tokyo	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	Direct	/	2026-05-10 04:47:40.599086	2026-05-10 04:47:40.599086	1	1	f	\N	2026-05-10 04:47:40.599086
316	a73e20ec-b0e9-4b76-aac9-995b2699f07f	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 04:51:57.629268	2026-05-10 04:51:57.629268	1	1	f	\N	2026-05-10 04:51:57.629268
317	2d051033-70d6-4903-b7f3-2d93e19d7dc1	93.123.109.222	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36	Andorra	Andorra la Vella	Andorra la Vella	Chrome 137.0.0	Windows 10	Desktop	Direct	/login	2026-05-10 04:52:20.473344	2026-05-10 04:52:20.473344	1	1	f	\N	2026-05-10 04:52:20.473344
318	3bfca07f-be86-4823-95a1-b63b9ec92ed4	45.8.19.91	Mozilla/5.0	United States	New York City	New York	Other 	Other 	Desktop	Direct	/wp-login.php	2026-05-10 04:54:47.740864	2026-05-10 04:54:47.740864	1	1	f	\N	2026-05-10 04:54:47.740864
319	13bfc2c6-550e-4d5e-ab47-b14ad41fb43e	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 04:57:32.675324	2026-05-10 04:57:32.675324	1	1	f	\N	2026-05-10 04:57:32.675324
320	ed7fba3d-2c2e-40a1-993e-dd1382f86e57	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 05:06:17.635117	2026-05-10 05:06:17.635117	1	1	f	\N	2026-05-10 05:06:17.635117
321	4c7ba489-256c-40af-9b50-3641a96fe144	18.214.206.100	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amzn-SearchBot/0.1) Chrome/119.0.6045.214 Safari/537.36	United States	Ashburn	Virginia	Amzn-SearchBot 0.1	Other 	Desktop	Direct	/login	2026-05-10 05:12:18.629425	2026-05-10 05:12:18.629425	1	1	f	\N	2026-05-10 05:12:18.629425
322	dc993eac-f8df-4809-b89b-08cb70fc6ea0	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	United States	Columbus	Ohio	Claude-SearchBot 1.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-10 05:12:36.608862	2026-05-10 05:12:36.608862	1	1	f	\N	2026-05-10 05:12:36.608862
323	7904bd45-6bad-4c65-868d-30141c6588ad	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 05:17:52.797017	2026-05-10 05:17:52.797017	1	1	f	\N	2026-05-10 05:17:52.797017
324	8064f700-8e6b-4603-a61b-3937aff98bc9	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 05:24:15.082213	2026-05-10 05:24:15.082213	1	1	f	\N	2026-05-10 05:24:15.082213
326	50cb4fc7-2e8d-46b4-a9da-f718af47c900	170.106.37.134	Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1	Unknown	Unknown	Unknown	Mobile Safari 13.0.3	iOS 13.2.3	Mobile	http://gspaces.in	/	2026-05-10 05:30:11.352604	2026-05-10 05:30:11.352604	1	1	f	\N	2026-05-10 05:30:11.352604
327	62e61e0c-44a5-4dd0-8f68-997b1a69a4ae	94.23.188.192	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	Unknown	Unknown	Unknown	AhrefsBot 7.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-10 05:36:06.394733	2026-05-10 05:36:06.394733	1	1	f	\N	2026-05-10 05:36:06.394733
328	9bef71dd-1b3e-4c47-80c9-93d4bea4e409	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 05:39:35.350954	2026-05-10 05:39:35.350954	1	1	f	\N	2026-05-10 05:39:35.350954
329	bb52e0cd-9edd-4a9b-a530-f3059ddcb99c	47.128.53.184	Mozilla/5.0 (Linux; Android 5.0) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; Bytespider; spider-feedback@bytedance.com)	Unknown	Unknown	Unknown	Bytespider 	Android 5.0	Mobile	Direct	/robots.txt	2026-05-10 05:43:30.226307	2026-05-10 05:43:30.226307	1	1	f	\N	2026-05-10 05:43:30.226307
325	4cbd5ff1-4833-46ec-89bb-77da32516c3e	2406:b400:b4:b6a:c536:8ac5:c96d:4e31	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	India	Hyderabad	Telangana	Chrome Mobile 148.0.0	Android 10	Mobile	Direct	/	2026-05-10 05:27:58.634513	2026-05-10 05:45:15.84318	22	22	t	14	2026-05-10 05:27:58.634513
330	b9b5e2e3-e426-4857-bbf7-7d25a03ccbbe	66.132.172.110	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/login	2026-05-10 05:46:37.61956	2026-05-10 05:46:37.61956	1	1	f	\N	2026-05-10 05:46:37.61956
331	36cd12bc-4424-4343-99ee-e0395fa153f0	66.132.172.110	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/favicon.ico	2026-05-10 05:46:47.34228	2026-05-10 05:46:47.34228	1	1	f	\N	2026-05-10 05:46:47.34228
332	6c4436f3-61ec-47ff-81d1-5137827e5f0a	66.132.172.110	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/rz22vmrxvcfswmfmc	2026-05-10 05:46:54.280421	2026-05-10 05:46:54.280421	1	1	f	\N	2026-05-10 05:46:54.280421
333	7826fe3e-c804-457d-b9f2-cdb2cd826864	66.132.195.108	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 05:47:59.102469	2026-05-10 05:47:59.102469	1	1	f	\N	2026-05-10 05:47:59.102469
334	aa16459a-9d13-49e8-81ff-28d382472644	66.132.195.108	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/favicon.ico	2026-05-10 05:48:06.612287	2026-05-10 05:48:06.612287	1	1	f	\N	2026-05-10 05:48:06.612287
335	1eb12c46-b94d-49cc-8791-f47a44e09d8c	66.132.195.108	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 05:48:31.419357	2026-05-10 05:48:31.419357	1	1	f	\N	2026-05-10 05:48:31.419357
336	8e4bbfb1-3348-418c-adc2-804b0757868c	66.132.195.108	Mozilla/5.0 (compatible; CensysInspect/1.1; +https://about.censys.io/)	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/security.txt	2026-05-10 05:48:43.210069	2026-05-10 05:48:43.210069	1	1	f	\N	2026-05-10 05:48:43.210069
337	dedb828f-98d8-4809-9084-0de1a0df8a4e	2a03:2880:f806:5::	meta-webindexer/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)	Unknown	Unknown	Unknown	meta-webindexer 1.1	Other 	Desktop	Direct	/product/22	2026-05-10 05:48:45.110492	2026-05-10 05:48:45.110492	1	1	f	\N	2026-05-10 05:48:45.110492
338	ea4a52c7-fb9a-46d8-8403-71d9ceb32739	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 05:51:04.841224	2026-05-10 05:51:04.841224	1	1	f	\N	2026-05-10 05:51:04.841224
339	183b5333-9868-48e9-b9ca-8eace104caeb	82.27.247.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	Unknown	Unknown	Unknown	Chrome 116.0.5845	Windows 10	Desktop	Direct	/.env	2026-05-10 05:56:59.056807	2026-05-10 05:56:59.056807	1	1	f	\N	2026-05-10 05:56:59.056807
340	c9972575-bdca-4cbe-81e7-b964c2938c07	82.27.247.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.140 Safari/537.36	Unknown	Unknown	Unknown	Chrome 116.0.5845	Windows 10	Desktop	Direct	/	2026-05-10 05:56:59.448645	2026-05-10 05:56:59.448645	1	1	f	\N	2026-05-10 05:56:59.448645
341	bb077754-8091-49a2-8962-0d0b98cfa4a3	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 05:57:43.781093	2026-05-10 05:57:43.781093	1	1	f	\N	2026-05-10 05:57:43.781093
342	bf235532-102d-43f5-91f1-5f43f0488801	178.18.247.3	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15	Unknown	Unknown	Unknown	Safari 15.1	Mac OS X 10.15.7	Desktop	Direct	/	2026-05-10 05:58:45.706714	2026-05-10 05:58:45.706714	1	1	f	\N	2026-05-10 05:58:45.706714
343	7f1745da-a0ba-44e2-85fe-54532e8682af	34.73.31.200	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36	Unknown	Unknown	Unknown	Chrome 39.0.2171	Mac OS X 10.10.1	Desktop	http://gspaces.in/media/system/js/core.js	/media/system/js/core.js	2026-05-10 06:11:24.218908	2026-05-10 06:11:24.218908	1	1	f	\N	2026-05-10 06:11:24.218908
344	dd45b35c-70ef-4143-8134-88892b4dcc92	34.73.31.200	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36	Unknown	Unknown	Unknown	Chrome 39.0.2171	Mac OS X 10.10.1	Desktop	http://gspaces.in/wp-includes/js/jquery/jquery.js	/wp-includes/js/jquery/jquery.js	2026-05-10 06:11:26.479489	2026-05-10 06:11:26.479489	1	1	f	\N	2026-05-10 06:11:26.479489
345	4ac1098b-6edb-4b22-b27d-342672e68c73	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 06:16:49.12869	2026-05-10 06:16:49.12869	1	1	f	\N	2026-05-10 06:16:49.12869
346	7f3ebcad-7d58-42a2-a737-f98a4a71fb1b	110.249.201.151	Mozilla/5.0 (Linux; Android 5.0) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; Bytespider; https://zhanzhang.toutiao.com/)	Unknown	Unknown	Unknown	Bytespider 	Android 5.0	Mobile	Direct	/robots.txt	2026-05-10 06:17:13.654813	2026-05-10 06:17:13.654813	1	1	f	\N	2026-05-10 06:17:13.654813
5	a7d280b3-6575-4bbb-b5b2-2fe850b1b5ed	2406:b400:b4:b6a:49a0:f609:780d:1ad6	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	India	Hyderabad	Telangana	Chrome 147.0.0	Mac OS X 10.15.7	Desktop	Direct	/admin/visitors	2026-05-09 17:45:26.713376	2026-05-10 06:21:27.31627	39	39	t	14	2026-05-09 17:45:26.713376
347	623c74ea-ad7d-4ab3-bc4f-840451002c68	2406:b400:b4:b6a:49a0:f609:780d:1ad6	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 147.0.0	Mac OS X 10.15.7	Desktop	Direct	/	2026-05-10 06:21:35.377742	2026-05-10 06:21:35.377742	1	1	f	\N	2026-05-10 06:21:35.377742
349	1f9f68b7-c59b-464a-9501-22b843a88089	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 06:26:06.849388	2026-05-10 06:26:06.849388	1	1	f	\N	2026-05-10 06:26:06.849388
348	3e49f9f7-0174-4a54-b3b9-62e27948acff	2406:b400:b4:b6a:49a0:f609:780d:1ad6	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 147.0.0	Mac OS X 10.15.7	Desktop	https://gspaces.in/admin/leads	/	2026-05-10 06:25:05.570552	2026-05-10 06:26:24.076309	5	5	f	\N	2026-05-10 06:25:05.570552
352	24819296-32f9-4e0f-96ca-5fe46a092715	54.209.139.3	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amzn-SearchBot/0.1) Chrome/119.0.6045.214 Safari/537.36	United States	Ashburn	Virginia	Amzn-SearchBot 0.1	Other 	Desktop	Direct	/my-workspace	2026-05-10 06:43:58.569599	2026-05-10 06:43:58.569599	1	1	f	\N	2026-05-10 06:43:58.569599
353	e1a2f69b-9ee3-42b7-ba86-6bdcfe3cd4b3	54.209.139.3	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amzn-SearchBot/0.1) Chrome/119.0.6045.214 Safari/537.36	United States	Ashburn	Virginia	Amzn-SearchBot 0.1	Other 	Desktop	Direct	/login	2026-05-10 06:43:59.233064	2026-05-10 06:43:59.233064	1	1	f	\N	2026-05-10 06:43:59.233064
354	100e1374-2468-438b-a767-ecc117c5c484	5.39.1.227	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	France	Paris	Ile-de-France	AhrefsBot 7.0	Other 	Desktop	Direct	/terms	2026-05-10 06:44:49.643751	2026-05-10 06:44:49.643751	1	1	f	\N	2026-05-10 06:44:49.643751
355	eaaa8e75-a693-4e11-9ebf-7663ca6ce909	204.76.203.206	Mozilla/5.0	Netherlands	Eygelshoven	Limburg	Other 	Other 	Desktop	Direct	/	2026-05-10 06:47:09.627192	2026-05-10 06:47:09.627192	1	1	f	\N	2026-05-10 06:47:09.627192
356	dc102c54-727c-412b-8811-aad8d51f55d6	43.129.169.161	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36	Hong Kong	Hong Kong	\N	Chrome 106.0.0	Windows 10	Desktop	Direct	/Core/Skin/Login.aspx	2026-05-10 06:51:00.95476	2026-05-10 06:51:00.95476	1	1	f	\N	2026-05-10 06:51:00.95476
357	480da258-1d5b-4b80-8f62-c0feec065532	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/	2026-05-10 06:51:12.394767	2026-05-10 06:51:12.394767	1	1	f	\N	2026-05-10 06:51:12.394767
358	24179934-a9e4-42a9-9155-028e57a45bf1	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/products	2026-05-10 06:51:12.461904	2026-05-10 06:51:12.461904	1	1	f	\N	2026-05-10 06:51:12.461904
359	720736fc-c9e1-40ad-921a-31d43145a8fe	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/about	2026-05-10 06:51:12.545482	2026-05-10 06:51:12.545482	1	1	f	\N	2026-05-10 06:51:12.545482
360	09f94c45-0417-4613-9bfd-ec47ea33b28b	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/contact	2026-05-10 06:51:12.58241	2026-05-10 06:51:12.58241	1	1	f	\N	2026-05-10 06:51:12.58241
361	4b7530d1-bd92-4234-a8f9-0f7f3b41a737	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/services	2026-05-10 06:51:12.625101	2026-05-10 06:51:12.625101	1	1	f	\N	2026-05-10 06:51:12.625101
362	a1865372-4bb8-4668-b0be-f5b9fbc79f5d	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/blogs	2026-05-10 06:51:12.65666	2026-05-10 06:51:12.65666	1	1	f	\N	2026-05-10 06:51:12.65666
363	1d569c19-cb10-44b5-9078-87cbccaf1f80	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/login	2026-05-10 06:51:12.716958	2026-05-10 06:51:12.716958	1	1	f	\N	2026-05-10 06:51:12.716958
364	92a86a49-610b-43e3-b000-5d2304e0ee47	127.0.0.1	python-requests/2.25.1	Unknown	Unknown	Unknown	Python Requests 2.25	Other 	Desktop	Direct	/signup	2026-05-10 06:51:12.756694	2026-05-10 06:51:12.756694	1	1	f	\N	2026-05-10 06:51:12.756694
365	a73ab2ac-e961-4198-99e7-af2b7888223e	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 06:52:33.718075	2026-05-10 06:52:33.718075	1	1	f	\N	2026-05-10 06:52:33.718075
366	8f24fe82-4cc3-4674-a151-1569676a3d5a	119.45.228.157	Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3464.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 69.0.3464	Windows 10	Desktop	Direct	/phpmyadmin/index.php	2026-05-10 07:00:10.612817	2026-05-10 07:00:10.612817	1	1	f	\N	2026-05-10 07:00:10.612817
367	06eb2077-0fe9-4a10-bba6-7f3fb661e130	119.45.228.157	Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3464.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 69.0.3464	Windows 10	Desktop	Direct	/pmd/index.php	2026-05-10 07:00:10.779332	2026-05-10 07:00:10.779332	1	1	f	\N	2026-05-10 07:00:10.779332
368	958e2b09-a27f-4c58-8517-d70354bf9057	119.45.228.157	Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3464.0 Safari/537.36	Unknown	Unknown	Unknown	Chrome 69.0.3464	Windows 10	Desktop	Direct	/phpmyadmin4.8.5/index.php	2026-05-10 07:00:10.94971	2026-05-10 07:00:10.94971	1	1	f	\N	2026-05-10 07:00:10.94971
369	c734af23-5e24-4865-b7fd-9da5d0d46122	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 07:02:33.718195	2026-05-10 07:02:33.718195	1	1	f	\N	2026-05-10 07:02:33.718195
370	a54b592f-b994-43c9-8f3a-81d4736ba230	216.73.217.71	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Claude-SearchBot/1.0; +searchbot@anthropic.com)	Unknown	Unknown	Unknown	Claude-SearchBot 1.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-10 07:07:14.130509	2026-05-10 07:07:14.130509	1	1	f	\N	2026-05-10 07:07:14.130509
371	795cbeb0-c45a-42cd-a627-7269dbaeea77	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 07:11:31.269711	2026-05-10 07:11:31.269711	1	1	f	\N	2026-05-10 07:11:31.269711
372	7aff0c5b-7e38-44dc-945f-4e24c5fe4e74	204.76.203.206	Mozilla/5.0	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 07:18:19.649187	2026-05-10 07:18:19.649187	1	1	f	\N	2026-05-10 07:18:19.649187
373	cdb17911-efb4-41e8-9950-e28745402b5c	37.59.204.149	Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)	Unknown	Unknown	Unknown	AhrefsBot 7.0	Other 	Desktop	Direct	/sitemap.xml	2026-05-10 07:22:11.047286	2026-05-10 07:22:11.047286	1	1	f	\N	2026-05-10 07:22:11.047286
374	36afe508-1330-43b3-86f9-295edc15e616	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/hello.world	2026-05-10 07:23:30.329645	2026-05-10 07:23:30.329645	1	1	f	\N	2026-05-10 07:23:30.329645
375	dfb252d5-8f3f-4f07-9fe4-3c3e59b4fbdd	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/	2026-05-10 07:23:31.102978	2026-05-10 07:23:31.102978	1	1	f	\N	2026-05-10 07:23:31.102978
376	4f7dbc82-6817-4de3-8887-472f91504cc7	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:31.539885	2026-05-10 07:23:31.539885	1	1	f	\N	2026-05-10 07:23:31.539885
377	198a2747-e7b3-4e62-91f8-74a72f683b1f	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/vendor/phpunit/phpunit/Util/PHP/eval-stdin.php	2026-05-10 07:23:32.007826	2026-05-10 07:23:32.007826	1	1	f	\N	2026-05-10 07:23:32.007826
378	d0c51928-b908-480a-b353-201ab41a9878	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/vendor/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:32.47297	2026-05-10 07:23:32.47297	1	1	f	\N	2026-05-10 07:23:32.47297
379	c8a8706f-6561-49a1-9ed3-939a4465e36c	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/vendor/phpunit/Util/PHP/eval-stdin.php	2026-05-10 07:23:33.10437	2026-05-10 07:23:33.10437	1	1	f	\N	2026-05-10 07:23:33.10437
380	2158191e-1048-48f5-ad81-0fdb8dc73e0b	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/vendor/phpunit/phpunit/LICENSE/eval-stdin.php	2026-05-10 07:23:33.602681	2026-05-10 07:23:33.602681	1	1	f	\N	2026-05-10 07:23:33.602681
381	a2dfa168-d3d7-4278-8176-33c5d5e36b1e	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/vendor/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:34.057381	2026-05-10 07:23:34.057381	1	1	f	\N	2026-05-10 07:23:34.057381
382	fd2b8a88-127a-4423-b3fb-e1f65009ac90	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:34.55359	2026-05-10 07:23:34.55359	1	1	f	\N	2026-05-10 07:23:34.55359
383	2d33503f-3976-47d8-a697-61ff17125f73	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/phpunit/phpunit/Util/PHP/eval-stdin.php	2026-05-10 07:23:35.233895	2026-05-10 07:23:35.233895	1	1	f	\N	2026-05-10 07:23:35.233895
384	062def44-7866-405d-a89b-c29ce2239315	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:35.881393	2026-05-10 07:23:35.881393	1	1	f	\N	2026-05-10 07:23:35.881393
385	3be5069d-d73c-4e87-abcf-0e6b3d99491b	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/phpunit/Util/PHP/eval-stdin.php	2026-05-10 07:23:36.624115	2026-05-10 07:23:36.624115	1	1	f	\N	2026-05-10 07:23:36.624115
386	c96e180c-a049-4f62-b8e6-6ac6af8d923b	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/lib/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:37.094242	2026-05-10 07:23:37.094242	1	1	f	\N	2026-05-10 07:23:37.094242
387	abccd373-b9ed-4917-bcb7-64bceb7dfe17	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/lib/phpunit/phpunit/Util/PHP/eval-stdin.php	2026-05-10 07:23:37.59841	2026-05-10 07:23:37.59841	1	1	f	\N	2026-05-10 07:23:37.59841
388	4d9af1dd-d491-478e-adfd-b37cb1eda4fd	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/lib/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:38.078747	2026-05-10 07:23:38.078747	1	1	f	\N	2026-05-10 07:23:38.078747
389	fc0db638-46cc-4831-9220-b0510d1399d5	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/lib/phpunit/Util/PHP/eval-stdin.php	2026-05-10 07:23:38.782319	2026-05-10 07:23:38.782319	1	1	f	\N	2026-05-10 07:23:38.782319
390	251154d1-42a5-4988-bd9a-3e0ee5622074	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/lib/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:39.159752	2026-05-10 07:23:39.159752	1	1	f	\N	2026-05-10 07:23:39.159752
391	cb44d120-a260-4799-bf0f-89b6d60acdf4	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/laravel/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:39.671391	2026-05-10 07:23:39.671391	1	1	f	\N	2026-05-10 07:23:39.671391
392	c6b98f4b-ec7b-48f0-b375-ae5916c8870c	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/www/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:40.130549	2026-05-10 07:23:40.130549	1	1	f	\N	2026-05-10 07:23:40.130549
393	0279e89f-a3e4-41a5-993b-76460541e26a	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/ws/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:40.68594	2026-05-10 07:23:40.68594	1	1	f	\N	2026-05-10 07:23:40.68594
394	7821fdfd-e118-41f7-961f-022065f1cdd1	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/yii/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:41.030069	2026-05-10 07:23:41.030069	1	1	f	\N	2026-05-10 07:23:41.030069
395	4a47a64f-411b-41a2-9929-b1aa57aa966f	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/zend/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:41.50827	2026-05-10 07:23:41.50827	1	1	f	\N	2026-05-10 07:23:41.50827
396	52f2fdef-7211-4b7c-b1ee-4529bbab496d	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/ws/ec/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:41.941168	2026-05-10 07:23:41.941168	1	1	f	\N	2026-05-10 07:23:41.941168
397	bd9551be-d7ad-40ea-bcad-38454b293c85	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/V2/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:42.582177	2026-05-10 07:23:42.582177	1	1	f	\N	2026-05-10 07:23:42.582177
398	fec270f9-8c8e-407e-94c1-e1595768ce91	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/tests/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:42.955848	2026-05-10 07:23:42.955848	1	1	f	\N	2026-05-10 07:23:42.955848
399	45de9d22-fd9a-4551-90d7-6cc00f455297	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/test/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:43.433672	2026-05-10 07:23:43.433672	1	1	f	\N	2026-05-10 07:23:43.433672
400	847c49ea-ba9d-4d9e-be1b-351f37ff04c5	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/testing/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:43.849538	2026-05-10 07:23:43.849538	1	1	f	\N	2026-05-10 07:23:43.849538
401	972716b4-74db-4187-8c89-aec26065866f	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/demo/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:44.60318	2026-05-10 07:23:44.60318	1	1	f	\N	2026-05-10 07:23:44.60318
402	5b85cccd-a6e0-48fc-accf-dcbb96ac04b9	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/cms/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:44.918161	2026-05-10 07:23:44.918161	1	1	f	\N	2026-05-10 07:23:44.918161
403	9ecc63b6-683b-4560-914f-49c86205f9d3	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/crm/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:45.275315	2026-05-10 07:23:45.275315	1	1	f	\N	2026-05-10 07:23:45.275315
404	44c15d07-980b-42c6-bc8c-7bf4b934b2a5	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/admin/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:45.614999	2026-05-10 07:23:45.614999	1	1	f	\N	2026-05-10 07:23:45.614999
405	5dc63aab-2da7-4d13-b612-dc03d7934c39	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/backup/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:46.082706	2026-05-10 07:23:46.082706	1	1	f	\N	2026-05-10 07:23:46.082706
406	d0c78cda-73a0-4081-a8c1-b0cb03892af8	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/blog/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:46.642572	2026-05-10 07:23:46.642572	1	1	f	\N	2026-05-10 07:23:46.642572
407	b78bf473-94f3-4b39-b688-fc9fcce81094	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/workspace/drupal/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:47.309317	2026-05-10 07:23:47.309317	1	1	f	\N	2026-05-10 07:23:47.309317
408	1e60492d-1ef8-434a-9d6a-0db84e54b27f	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/panel/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:47.91696	2026-05-10 07:23:47.91696	1	1	f	\N	2026-05-10 07:23:47.91696
409	60183897-89e6-4272-b58f-7c04d2663bea	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/public/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:48.47214	2026-05-10 07:23:48.47214	1	1	f	\N	2026-05-10 07:23:48.47214
410	b92db2d7-9b29-4031-8772-cfdcbbf9e048	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/apps/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:48.966249	2026-05-10 07:23:48.966249	1	1	f	\N	2026-05-10 07:23:48.966249
411	c19d6801-d649-40ea-b714-1340f83e445a	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/app/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php	2026-05-10 07:23:49.547184	2026-05-10 07:23:49.547184	1	1	f	\N	2026-05-10 07:23:49.547184
412	aecd52d1-972e-4c89-aa88-3fd8a5f44536	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/index.php	2026-05-10 07:23:50.04378	2026-05-10 07:23:50.04378	1	1	f	\N	2026-05-10 07:23:50.04378
413	ed293d04-c906-4734-8bfe-fb732251c161	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/public/index.php	2026-05-10 07:23:50.62616	2026-05-10 07:23:50.62616	1	1	f	\N	2026-05-10 07:23:50.62616
414	632dde81-c845-4c61-9a9c-e75dc0ae7093	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/index.php	2026-05-10 07:23:51.069749	2026-05-10 07:23:51.069749	1	1	f	\N	2026-05-10 07:23:51.069749
415	e92c7664-4d78-4b43-9cd5-dcb006a17a31	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/index.php	2026-05-10 07:23:51.493286	2026-05-10 07:23:51.493286	1	1	f	\N	2026-05-10 07:23:51.493286
416	d415f4ec-b4c8-4aa2-866c-cc7a25826a5e	146.190.89.51	libredtail-http	Unknown	Unknown	Unknown	Other 	Other 	Desktop	Direct	/containers/json	2026-05-10 07:23:51.845889	2026-05-10 07:23:51.845889	1	1	f	\N	2026-05-10 07:23:51.845889
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
31	14	bonus	1000.00	1500.00	Coupon redeemed: GSPACES_DESKS_FOLLOW	coupon	10	2026-04-28 19:58:56.760881	{"coupon_code": "GSPACES_DESKS_FOLLOW", "coupon_type": "wallet"}
32	14	bonus	1000.00	2500.00	Coupon redeemed: GSPACES_DESKS_FOLLOW	coupon	10	2026-04-28 20:00:19.916712	{"coupon_code": "GSPACES_DESKS_FOLLOW", "coupon_type": "wallet"}
33	14	bonus	1000.00	3500.00	Coupon redeemed: GSPACES_DESKS_FOLLOW	coupon	10	2026-04-28 20:01:26.80342	{"coupon_code": "GSPACES_DESKS_FOLLOW", "coupon_type": "wallet"}
34	34	bonus	1000.00	1500.00	Coupon redeemed: GSPACES_DESKS_FOLLOW	coupon	10	2026-04-28 20:12:05.547674	{"coupon_code": "GSPACES_DESKS_FOLLOW", "coupon_type": "wallet"}
35	35	bonus	500.00	500.00	Welcome bonus for sreekanth chityala	signup	\N	2026-04-28 20:19:24.449948	{"bonus_type": "signup"}
36	35	bonus	1000.00	1500.00	Coupon redeemed: GSPACES_DESKS_FOLLOW	coupon	10	2026-04-28 20:19:33.159165	{"coupon_code": "GSPACES_DESKS_FOLLOW", "coupon_type": "wallet"}
37	36	bonus	500.00	500.00	Welcome bonus for Home	signup	\N	2026-04-30 13:08:17.126285	{"bonus_type": "signup"}
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
-- Name: animated_banner_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.animated_banner_settings_id_seq', 1, false);


--
-- Name: animated_furniture_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.animated_furniture_items_id_seq', 15, true);


--
-- Name: blog_comments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.blog_comments_id_seq', 1, false);


--
-- Name: blog_media_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.blog_media_id_seq', 33, true);


--
-- Name: blog_reactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.blog_reactions_id_seq', 9, true);


--
-- Name: cart_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.cart_id_seq', 102, true);


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_id_seq', 14, true);


--
-- Name: category_discounts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.category_discounts_id_seq', 3, true);


--
-- Name: coupon_usage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.coupon_usage_id_seq', 5, true);


--
-- Name: coupons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.coupons_id_seq', 14, true);


--
-- Name: customer_blogs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.customer_blogs_id_seq', 26, true);


--
-- Name: customer_inquiries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.customer_inquiries_id_seq', 6, true);


--
-- Name: deal_campaigns_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.deal_campaigns_id_seq', 3, true);


--
-- Name: default_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.default_items_id_seq', 53, true);


--
-- Name: design_custom_fields_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.design_custom_fields_id_seq', 1, false);


--
-- Name: design_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.design_items_id_seq', 1, false);


--
-- Name: discount_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.discount_id_seq', 58, true);


--
-- Name: error_alerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.error_alerts_id_seq', 76, true);


--
-- Name: global_discount_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.global_discount_id_seq', 1, true);


--
-- Name: gst_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.gst_settings_id_seq', 1, true);


--
-- Name: homepage_banner_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.homepage_banner_id_seq', 3, true);


--
-- Name: homepage_carousel_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.homepage_carousel_images_id_seq', 3, true);


--
-- Name: item_default_prices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.item_default_prices_id_seq', 56, true);


--
-- Name: lead_designs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.lead_designs_id_seq', 15, true);


--
-- Name: leads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.leads_id_seq', 17, true);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.order_items_id_seq', 50, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.orders_id_seq', 59, true);


--
-- Name: otp_verifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.otp_verifications_id_seq', 5, true);


--
-- Name: page_views_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.page_views_id_seq', 858, true);


--
-- Name: pricing_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.pricing_rules_id_seq', 24, true);


--
-- Name: product_reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.product_reviews_id_seq', 2, true);


--
-- Name: product_sub_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.product_sub_images_id_seq', 133, true);


--
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.products_id_seq', 31, true);


--
-- Name: referral_coupons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.referral_coupons_id_seq', 70, true);


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
-- Name: room_visualizations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.room_visualizations_id_seq', 5, true);


--
-- Name: system_health_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.system_health_logs_id_seq', 1, false);


--
-- Name: user_workspace_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.user_workspace_items_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.users_id_seq', 36, true);


--
-- Name: visitor_tracking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.visitor_tracking_id_seq', 416, true);


--
-- Name: wallet_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sri
--

SELECT pg_catalog.setval('public.wallet_transactions_id_seq', 37, true);


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
-- Name: animated_banner_settings animated_banner_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.animated_banner_settings
    ADD CONSTRAINT animated_banner_settings_pkey PRIMARY KEY (id);


--
-- Name: animated_furniture_items animated_furniture_items_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.animated_furniture_items
    ADD CONSTRAINT animated_furniture_items_pkey PRIMARY KEY (id);


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
-- Name: category_discounts category_discounts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_discounts
    ADD CONSTRAINT category_discounts_pkey PRIMARY KEY (id);


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
-- Name: customer_inquiries customer_inquiries_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.customer_inquiries
    ADD CONSTRAINT customer_inquiries_pkey PRIMARY KEY (id);


--
-- Name: deal_campaigns deal_campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.deal_campaigns
    ADD CONSTRAINT deal_campaigns_pkey PRIMARY KEY (id);


--
-- Name: default_items default_items_item_name_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.default_items
    ADD CONSTRAINT default_items_item_name_key UNIQUE (item_name);


--
-- Name: default_items default_items_item_slug_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.default_items
    ADD CONSTRAINT default_items_item_slug_key UNIQUE (item_slug);


--
-- Name: default_items default_items_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.default_items
    ADD CONSTRAINT default_items_pkey PRIMARY KEY (id);


--
-- Name: design_custom_fields design_custom_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.design_custom_fields
    ADD CONSTRAINT design_custom_fields_pkey PRIMARY KEY (id);


--
-- Name: design_items design_items_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.design_items
    ADD CONSTRAINT design_items_pkey PRIMARY KEY (id);


--
-- Name: discount discount_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.discount
    ADD CONSTRAINT discount_pkey PRIMARY KEY (id);


--
-- Name: error_alerts error_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.error_alerts
    ADD CONSTRAINT error_alerts_pkey PRIMARY KEY (id);


--
-- Name: global_discount global_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.global_discount
    ADD CONSTRAINT global_discount_pkey PRIMARY KEY (id);


--
-- Name: gst_settings gst_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.gst_settings
    ADD CONSTRAINT gst_settings_pkey PRIMARY KEY (id);


--
-- Name: homepage_banner homepage_banner_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.homepage_banner
    ADD CONSTRAINT homepage_banner_pkey PRIMARY KEY (id);


--
-- Name: homepage_carousel_images homepage_carousel_images_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.homepage_carousel_images
    ADD CONSTRAINT homepage_carousel_images_pkey PRIMARY KEY (id);


--
-- Name: item_default_prices item_default_prices_item_name_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.item_default_prices
    ADD CONSTRAINT item_default_prices_item_name_key UNIQUE (item_name);


--
-- Name: item_default_prices item_default_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.item_default_prices
    ADD CONSTRAINT item_default_prices_pkey PRIMARY KEY (id);


--
-- Name: lead_designs lead_designs_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.lead_designs
    ADD CONSTRAINT lead_designs_pkey PRIMARY KEY (id);


--
-- Name: leads leads_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);


--
-- Name: leads leads_share_token_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_share_token_key UNIQUE (share_token);


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
-- Name: page_views page_views_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT page_views_pkey PRIMARY KEY (id);


--
-- Name: pricing_rules pricing_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.pricing_rules
    ADD CONSTRAINT pricing_rules_pkey PRIMARY KEY (id);


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
-- Name: room_visualizations room_visualizations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_visualizations
    ADD CONSTRAINT room_visualizations_pkey PRIMARY KEY (id);


--
-- Name: system_health_logs system_health_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.system_health_logs
    ADD CONSTRAINT system_health_logs_pkey PRIMARY KEY (id);


--
-- Name: coupon_usage unique_coupon_user_usage; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT unique_coupon_user_usage UNIQUE (coupon_id, user_id, usage_type);


--
-- Name: referral_coupons unique_user_referral; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.referral_coupons
    ADD CONSTRAINT unique_user_referral UNIQUE (user_id);


--
-- Name: user_workspace_items user_workspace_items_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.user_workspace_items
    ADD CONSTRAINT user_workspace_items_pkey PRIMARY KEY (id);


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
-- Name: visitor_tracking visitor_tracking_pkey; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.visitor_tracking
    ADD CONSTRAINT visitor_tracking_pkey PRIMARY KEY (id);


--
-- Name: visitor_tracking visitor_tracking_visitor_id_key; Type: CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.visitor_tracking
    ADD CONSTRAINT visitor_tracking_visitor_id_key UNIQUE (visitor_id);


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
-- Name: idx_animated_furniture_active; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_animated_furniture_active ON public.animated_furniture_items USING btree (is_active, display_order);


--
-- Name: idx_animated_furniture_category; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_animated_furniture_category ON public.animated_furniture_items USING btree (category);


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
-- Name: idx_campaigns_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_campaigns_active ON public.deal_campaigns USING btree (is_active);


--
-- Name: idx_campaigns_dates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_campaigns_dates ON public.deal_campaigns USING btree (start_time, end_time);


--
-- Name: idx_carousel_images_active; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_carousel_images_active ON public.homepage_carousel_images USING btree (is_active, display_order);


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
-- Name: idx_category_discounts_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_category_discounts_active ON public.category_discounts USING btree (is_active);


--
-- Name: idx_category_discounts_campaign; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_category_discounts_campaign ON public.category_discounts USING btree (campaign_id);


--
-- Name: idx_category_discounts_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_category_discounts_category ON public.category_discounts USING btree (category_id);


--
-- Name: idx_coupon_usage_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_coupon_usage_user_id ON public.coupon_usage USING btree (user_id);


--
-- Name: idx_coupon_usage_user_type; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_coupon_usage_user_type ON public.coupon_usage USING btree (user_id, usage_type);


--
-- Name: idx_coupons_type; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_coupons_type ON public.coupons USING btree (coupon_type);


--
-- Name: idx_coupons_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_coupons_user_id ON public.coupons USING btree (user_id);


--
-- Name: idx_custom_fields_design_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_custom_fields_design_id ON public.design_custom_fields USING btree (design_id);


--
-- Name: idx_customer_inquiries_budget; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_customer_inquiries_budget ON public.customer_inquiries USING btree (budget_range);


--
-- Name: idx_customer_inquiries_created_at; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_customer_inquiries_created_at ON public.customer_inquiries USING btree (created_at DESC);


--
-- Name: idx_customer_inquiries_setup_type; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_customer_inquiries_setup_type ON public.customer_inquiries USING btree (setup_type);


--
-- Name: idx_customer_inquiries_status; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_customer_inquiries_status ON public.customer_inquiries USING btree (status);


--
-- Name: idx_default_items_active; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_default_items_active ON public.default_items USING btree (is_active);


--
-- Name: idx_default_items_icon_image; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_default_items_icon_image ON public.default_items USING btree (icon_image) WHERE (icon_image IS NOT NULL);


--
-- Name: idx_default_items_order; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_default_items_order ON public.default_items USING btree (display_order);


--
-- Name: idx_default_items_slug; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_default_items_slug ON public.default_items USING btree (item_slug);


--
-- Name: idx_design_items_design_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_design_items_design_id ON public.design_items USING btree (design_id);


--
-- Name: idx_error_alerts_created_at; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_error_alerts_created_at ON public.error_alerts USING btree (created_at);


--
-- Name: idx_error_alerts_error_type; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_error_alerts_error_type ON public.error_alerts USING btree (error_type);


--
-- Name: idx_error_alerts_is_notified; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_error_alerts_is_notified ON public.error_alerts USING btree (is_notified);


--
-- Name: idx_error_alerts_severity; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_error_alerts_severity ON public.error_alerts USING btree (severity);


--
-- Name: idx_global_discount_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_global_discount_active ON public.global_discount USING btree (is_active);


--
-- Name: idx_global_discount_campaign; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_global_discount_campaign ON public.global_discount USING btree (campaign_id);


--
-- Name: idx_homepage_banner_active; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_homepage_banner_active ON public.homepage_banner USING btree (is_active);


--
-- Name: idx_lead_designs_lead_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_lead_designs_lead_id ON public.lead_designs USING btree (lead_id);


--
-- Name: idx_lead_designs_media; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_lead_designs_media ON public.lead_designs USING gin (media_files);


--
-- Name: idx_lead_designs_profile_lighting; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_lead_designs_profile_lighting ON public.lead_designs USING btree (has_profile_lighting) WHERE (has_profile_lighting = true);


--
-- Name: idx_leads_created_by; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_leads_created_by ON public.leads USING btree (created_by);


--
-- Name: idx_leads_feedback_submitted; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_leads_feedback_submitted ON public.leads USING btree (feedback_submitted_at) WHERE (feedback_submitted_at IS NOT NULL);


--
-- Name: idx_leads_is_expired; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_leads_is_expired ON public.leads USING btree (is_expired);


--
-- Name: idx_leads_share_token; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_leads_share_token ON public.leads USING btree (share_token);


--
-- Name: idx_leads_valid_until; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_leads_valid_until ON public.leads USING btree (valid_until);


--
-- Name: idx_otp_email; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_otp_email ON public.otp_verifications USING btree (email);


--
-- Name: idx_otp_expires; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_otp_expires ON public.otp_verifications USING btree (expires_at);


--
-- Name: idx_page_views_created_at; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_page_views_created_at ON public.page_views USING btree (created_at);


--
-- Name: idx_page_views_page_url; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_page_views_page_url ON public.page_views USING btree (page_url);


--
-- Name: idx_page_views_session_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_page_views_session_id ON public.page_views USING btree (session_id);


--
-- Name: idx_page_views_visitor_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_page_views_visitor_id ON public.page_views USING btree (visitor_id);


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
-- Name: idx_product_visualizations; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_product_visualizations ON public.room_visualizations USING btree (product_id, created_at DESC);


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
-- Name: idx_system_health_check_type; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_system_health_check_type ON public.system_health_logs USING btree (check_type);


--
-- Name: idx_system_health_created_at; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_system_health_created_at ON public.system_health_logs USING btree (created_at);


--
-- Name: idx_system_health_status; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_system_health_status ON public.system_health_logs USING btree (status);


--
-- Name: idx_user_visualizations; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_visualizations ON public.room_visualizations USING btree (user_id, created_at DESC);


--
-- Name: idx_user_workspace_items_active; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_user_workspace_items_active ON public.user_workspace_items USING btree (user_id, is_active);


--
-- Name: idx_user_workspace_items_user_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_user_workspace_items_user_id ON public.user_workspace_items USING btree (user_id);


--
-- Name: idx_users_admin_level; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_users_admin_level ON public.users USING btree (admin_level);


--
-- Name: idx_users_referral_code; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_users_referral_code ON public.users USING btree (referral_code);


--
-- Name: idx_visitor_tracking_country; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_visitor_tracking_country ON public.visitor_tracking USING btree (country);


--
-- Name: idx_visitor_tracking_ip; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_visitor_tracking_ip ON public.visitor_tracking USING btree (ip_address);


--
-- Name: idx_visitor_tracking_last_visit; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_visitor_tracking_last_visit ON public.visitor_tracking USING btree (last_visit);


--
-- Name: idx_visitor_tracking_visitor_id; Type: INDEX; Schema: public; Owner: sri
--

CREATE INDEX idx_visitor_tracking_visitor_id ON public.visitor_tracking USING btree (visitor_id);


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
-- Name: category_discounts update_category_discounts_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_category_discounts_updated_at BEFORE UPDATE ON public.category_discounts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: customer_inquiries update_customer_inquiry_timestamp; Type: TRIGGER; Schema: public; Owner: sri
--

CREATE TRIGGER update_customer_inquiry_timestamp BEFORE UPDATE ON public.customer_inquiries FOR EACH ROW EXECUTE FUNCTION public.update_customer_inquiry_timestamp();


--
-- Name: deal_campaigns update_deal_campaigns_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_deal_campaigns_updated_at BEFORE UPDATE ON public.deal_campaigns FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: default_items update_default_items_updated_at; Type: TRIGGER; Schema: public; Owner: sri
--

CREATE TRIGGER update_default_items_updated_at BEFORE UPDATE ON public.default_items FOR EACH ROW EXECUTE FUNCTION public.update_default_items_timestamp();


--
-- Name: design_items update_design_items_updated_at; Type: TRIGGER; Schema: public; Owner: sri
--

CREATE TRIGGER update_design_items_updated_at BEFORE UPDATE ON public.design_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: global_discount update_global_discount_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_global_discount_updated_at BEFORE UPDATE ON public.global_discount FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: leads update_leads_updated_at; Type: TRIGGER; Schema: public; Owner: sri
--

CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON public.leads FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: visitor_tracking update_visitor_tracking_updated_at; Type: TRIGGER; Schema: public; Owner: sri
--

CREATE TRIGGER update_visitor_tracking_updated_at BEFORE UPDATE ON public.visitor_tracking FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


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
-- Name: category_discounts category_discounts_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category_discounts
    ADD CONSTRAINT category_discounts_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.deal_campaigns(id) ON DELETE CASCADE;


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
-- Name: customer_inquiries customer_inquiries_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.customer_inquiries
    ADD CONSTRAINT customer_inquiries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: design_custom_fields design_custom_fields_design_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.design_custom_fields
    ADD CONSTRAINT design_custom_fields_design_id_fkey FOREIGN KEY (design_id) REFERENCES public.lead_designs(id) ON DELETE CASCADE;


--
-- Name: design_items design_items_design_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.design_items
    ADD CONSTRAINT design_items_design_id_fkey FOREIGN KEY (design_id) REFERENCES public.lead_designs(id) ON DELETE CASCADE;


--
-- Name: global_discount global_discount_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.global_discount
    ADD CONSTRAINT global_discount_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.deal_campaigns(id) ON DELETE CASCADE;


--
-- Name: lead_designs lead_designs_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.lead_designs
    ADD CONSTRAINT lead_designs_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE CASCADE;


--
-- Name: leads leads_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


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
-- Name: page_views page_views_visitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT page_views_visitor_id_fkey FOREIGN KEY (visitor_id) REFERENCES public.visitor_tracking(visitor_id) ON DELETE CASCADE;


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
-- Name: room_visualizations room_visualizations_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_visualizations
    ADD CONSTRAINT room_visualizations_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: room_visualizations room_visualizations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.room_visualizations
    ADD CONSTRAINT room_visualizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_workspace_items user_workspace_items_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.user_workspace_items
    ADD CONSTRAINT user_workspace_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users users_referred_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_referred_by_user_id_fkey FOREIGN KEY (referred_by_user_id) REFERENCES public.users(id);


--
-- Name: visitor_tracking visitor_tracking_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sri
--

ALTER TABLE ONLY public.visitor_tracking
    ADD CONSTRAINT visitor_tracking_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


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

\unrestrict c15xOwbe00wNPZLPw7xv1Hd0zyrFELO4KlrBsWowUR97QH29zrgJwWvdpcsvLKq

