-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 22, 2025 at 07:44 PM
-- Server version: 8.0.30
-- PHP Version: 8.2.27

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `mvc_admin_lyroz`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteAttribute` (IN `ID_ATTR` INT)   BEGIN
	IF EXISTS(SELECT 3 AS ERRNO FROM ir_attribute WHERE id_attribute = ID_ATTR) THEN
		IF NOT EXISTS(SELECT 3 AS ERRNO FROM ir_product_lang_attribute WHERE id_attribute = ID_ATTR) THEN
			IF (ID_ATTR > 1) THEN
				BEGIN
					/*ANTES DE ELIMINAR ATRIBUTO, PRIMERO DESASOCIAMOS LAS SUBATRIBUTOS*/
					UPDATE ir_attribute
					SET	parent_id_attribute 		= 0
						WHERE parent_id_attribute 	= ID_ATTR;

					DELETE FROM ir_attribute WHERE id_attribute = ID_ATTR;
	
					SELECT 4 AS ERRNO;
				END;
			ELSE
				/*TIENE ATRIBUTOS PRINCIPALES*/
				BEGIN
					SELECT 3 AS ERRNO;
				END;
			END IF;
		ELSE
			/*NO TIENE PRODUCTOS REGISTRADOS*/
			BEGIN
				SELECT 2 AS ERRNO;
			END;
		END IF;
	ELSE
		/*EL ID ATRIBUTO NO EXISTE*/
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteCategory` (IN `ID_C` INT)   BEGIN
	/* Manejador de errores para revertir la transacción */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; /* Error genérico de SQL */
	END;

	/* 1. EL ID CATEGORIA NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_category WHERE id_category = ID_C LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. TIENE PRODUCTOS REGISTRADOS */
	ELSEIF EXISTS(SELECT 1 FROM ir_product_category WHERE id_category = ID_C LIMIT 1) THEN
		SELECT 2 AS ERRNO;
		
	/* 3. ES UNA CATEGORIA PRINCIPAL (PROTEGIDA) */
	ELSEIF (ID_C <= 3) THEN
		SELECT 3 AS ERRNO;
		
	/* 4. TIENE BLOGS REGISTRADOS */
	ELSEIF EXISTS(SELECT 1 FROM ir_blog_category WHERE id_category = ID_C LIMIT 1) THEN
		SELECT 4 AS ERRNO;

	/* 5. Proceder con la eliminación */
	ELSE
		/* Iniciar transacción */
		START TRANSACTION;

		/* ANTES DE ELIMINAR CATEGORIA, PRIMERO DESASOCIAMOS LAS SUBCATEGORIAS */
		UPDATE ir_category
		SET	parent_id = 0
		WHERE parent_id = ID_C;

		DELETE FROM ir_category WHERE id_category = ID_C;
	
		/* Confirmar transacción */
		COMMIT;
		
		SELECT 5 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteCategoryLangImageLang` (IN `ID_C_LA_IMG_LA` INT)   BEGIN
	DECLARE v_id_image_lang INT;

	/* Manejador de errores para revertir la transacción */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; /* Error genérico de SQL */
	END;

	/* 1. OPTIMIZACIÓN: Obtener el ID_IMAGE_LANG a borrar. */
	SELECT 
		c_l_img_l.id_image_lang 
	INTO v_id_image_lang
	FROM ir_category_lang_image_lang c_l_img_l
	INNER JOIN ir_image_lang img_l 
		ON img_l.id_image_lang=c_l_img_l.id_image_lang
	WHERE c_l_img_l.id_category_lang_image_lang = ID_C_LA_IMG_LA;

	/* 2. Comprobar si se encontró el registro */
	IF FOUND_ROWS() = 0 THEN
		/* No se encontró el enlace */
		SELECT 1 AS ERRNO;
	ELSE
		/* 3. Registro encontrado, proceder con borrado transaccional */
		
		/* Iniciar transacción */
		START TRANSACTION;

		DELETE FROM ir_image_lang 
		WHERE id_image_lang = v_id_image_lang;

		DELETE FROM ir_category_lang_image_lang 
		WHERE id_category_lang_image_lang = ID_C_LA_IMG_LA;

		/* Confirmar transacción */
		COMMIT;

		SELECT 2 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteCategoryWithImage` (IN `ID_C` INT)   BEGIN
	/* Manejador de errores para revertir la transacción */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; /* Error genérico de SQL */
	END;

	/* 1. Comprobar si la categoría existe Y tiene imágenes */
	IF EXISTS(SELECT 1
			FROM ir_category c 
			INNER JOIN ir_category_lang c_l 
				ON c.id_category=c_l.id_category
			INNER JOIN ir_category_lang_image_lang c_l_img_l 
				ON c_l_img_l.id_category_lang=c_l.id_category_lang
			INNER JOIN ir_image_lang img_l 
				ON img_l.id_image_lang=c_l_img_l.id_image_lang
			INNER JOIN ir_image img 
				ON img.id_image=img_l.id_image
			WHERE c.id_category = ID_C
			LIMIT 1) THEN
		
		/* 2. Proceder con la eliminación */
		/* Iniciar transacción */
		START TRANSACTION;
			
		/* ANTES DE ELIMINAR CATEGORIA, PRIMERO DESASOCIAMOS LAS SUBCATEGORIAS */
		UPDATE ir_category
		SET	parent_id = 0
		WHERE parent_id = ID_C;
		
		/* SE ELIMINA TODA LA IMAGEN */
		DELETE img
		FROM ir_category c 
		INNER JOIN ir_category_lang c_l 
			ON c.id_category=c_l.id_category
		INNER JOIN ir_category_lang_image_lang c_l_img_l 
			ON c_l_img_l.id_category_lang=c_l.id_category_lang
		INNER JOIN ir_image_lang img_l 
			ON img_l.id_image_lang=c_l_img_l.id_image_lang
		INNER JOIN ir_image img 
			ON img.id_image=img_l.id_image	
		WHERE c.id_category = ID_C;

		/* SE ELIMINA LA CATEGORIA */
		DELETE FROM ir_category 
		WHERE id_category = ID_C;

		/* Confirmar transacción */
		COMMIT;

		SELECT 2 AS ERRNO;
		
	ELSE
		/* No se encontró la categoría O no tenía imágenes */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteImage` (IN `ID_IMG` INT)   BEGIN
	DELETE
	FROM ir_image
	WHERE id_image = ID_IMG;
	
	/* Comprobar si el DELETE afectó a alguna fila */
	IF ROW_COUNT() > 0 THEN
		/* La imagen existía y fue eliminada */
		SELECT 2 AS ERRNO;
	ELSE
		/* La imagen no existía (ninguna fila fue eliminada) */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteImageVersion` (IN `ID_IMG_LA_V` INT)   BEGIN
	DELETE
	FROM ir_image_lang_version
	WHERE id_image_lang_version = ID_IMG_LA_V;
	
	/* Comprobar si el DELETE afectó a alguna fila */
	IF ROW_COUNT() > 0 THEN
		/* El registro existía y fue eliminado */
		SELECT 2 AS ERRNO;
	ELSE
		/* El registro no existía (ninguna fila fue eliminada) */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteProduct` (IN `ID_P` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO FROM ir_product WHERE id_product = ID_P) THEN
		BEGIN
			DELETE FROM ir_product WHERE id_product = ID_P;
	
			SELECT 2 AS ERRNO;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteProductAdditionalInformation` (IN `ID_P_LA_ADD_I` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_product_lang_additional_information
				WHERE id_product_lang_additional_information = ID_P_LA_ADD_I) THEN
		BEGIN
			DELETE FROM ir_product_lang_additional_information
				WHERE id_product_lang_additional_information = ID_P_LA_ADD_I;

			SELECT 2 AS ERRNO;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteProductPromotion` (IN `ID_P_LA_PROM` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_product_lang_promotion
				WHERE id_product_lang_promotion = ID_P_LA_PROM) THEN
		BEGIN
			DELETE FROM ir_product_lang_promotion
				WHERE id_product_lang_promotion = ID_P_LA_PROM;

			SELECT 2 AS ERRNO;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteProductWithImage` (IN `ID_P` INT)   BEGIN
	IF EXISTS(SELECT 5 AS ERRNO FROM ir_product WHERE id_product = ID_P) THEN
		
		/*TIENE PORTADA REGISTRADA*/
		IF EXISTS(SELECT 5 AS ERRNO 
				FROM ir_product_lang_image_lang p_l_img_l
				INNER JOIN ir_product_lang p_l 
					ON p_l_img_l.id_product_lang=p_l.id_product_lang
					WHERE p_l.id_product = ID_P) THEN

			/*TIENE PRESENTACION SIN IMAGEN*/
			IF EXISTS(SELECT 5 AS ERRNO
					FROM ir_product_lang_presentation p_l_pre
					INNER JOIN ir_product_lang p_l 
						ON p_l.id_product_lang=p_l_pre.id_product_lang
							WHERE p_l.id_product = ID_P) THEN

				/*TIENE PRESENTACION CON IMAGEN*/
				IF EXISTS(SELECT 5 AS ERRNO
						FROM ir_product_lang_presentation_image_lang p_la_pre_img
						INNER JOIN ir_product_lang_presentation p_l_pre
							ON p_la_pre_img.id_product_lang_presentation=p_l_pre.id_product_lang_presentation
						INNER JOIN ir_product_lang p_l
							ON p_l.id_product_lang=p_l_pre.id_product_lang
								WHERE p_l.id_product = ID_P) THEN

					/*TIENE ARCHIVOS REGISTRADOS*/
					IF EXISTS(SELECT 5 AS ERRNO
							FROM ir_product_lang_presentation_lang_file_lang p_la_pre_la_fi_l
							INNER JOIN ir_product_lang_presentation_lang p_l_pre_l
								ON p_la_pre_la_fi_l.id_product_lang_presentation_lang=p_l_pre_l.id_product_lang_presentation_lang
							INNER JOIN ir_product_lang_presentation p_l_pre
								ON p_l_pre.id_product_lang_presentation=p_l_pre_l.id_product_lang_presentation
							INNER JOIN ir_product_lang p_l
								ON p_l.id_product_lang=p_l_pre.id_product_lang
									WHERE p_l.id_product = ID_P) THEN

							/*TIENE PORTADA, PRESENTACION SIN IMAGEN, PRESENTACION CON IMAGEN Y ARCHIVOS*/
							BEGIN
								/*ELIMINAR ARCHIVOS*/
								DELETE f
									FROM ir_product_lang_presentation_lang_file_lang p_la_pre_la_fi_l
									INNER JOIN ir_product_lang_presentation_lang p_l_pre_l
										ON p_la_pre_la_fi_l.id_product_lang_presentation_lang=p_l_pre_l.id_product_lang_presentation_lang
									INNER JOIN ir_file_lang f_l
										ON f_l.id_file_lang=p_la_pre_la_fi_l.id_file_lang
									INNER JOIN ir_file f
										ON f.id_file=f_l.id_file
									INNER JOIN ir_product_lang_presentation p_l_pre
										ON p_l_pre.id_product_lang_presentation=p_l_pre_l.id_product_lang_presentation
									INNER JOIN ir_product_lang p_l
										ON p_l.id_product_lang=p_l_pre.id_product_lang
											WHERE p_l.id_product = ID_P;

								/*PRESENTACION CON IMAGEN*/
								DELETE img 
									FROM ir_product_lang_presentation_image_lang p_la_pre_img_l
									INNER JOIN ir_product_lang_presentation p_l_pre
										ON p_la_pre_img_l.id_product_lang_presentation=p_l_pre.id_product_lang_presentation
									INNER JOIN ir_product_lang p_l
										ON p_l.id_product_lang=p_l_pre.id_product_lang
									INNER JOIN ir_image_lang img_l
										ON img_l.id_image_lang=p_la_pre_img_l.id_image_lang
									INNER JOIN ir_image img
										ON img.id_image=img_l.id_image
											WHERE p_l.id_product = ID_P;

								/*ELIMINAR PORTADAS Y/O GENERALES Y PRODUCTO*/
								DELETE img, p
									FROM ir_product_lang_image_lang p_l_img_l
									INNER JOIN ir_product_lang p_l 
										ON p_l_img_l.id_product_lang=p_l.id_product_lang
									INNER JOIN ir_product p
										ON p.id_product=p_l.id_product
									INNER JOIN ir_image_lang img_l
										ON img_l.id_image_lang=p_l_img_l.id_image_lang
									INNER JOIN ir_image img
										ON img.id_image=img_l.id_image
											WHERE p_l.id_product = ID_P;
	
								SELECT 5 AS ERRNO;
							END;
					ELSE
						/*TIENE PORTADA, PRESENTACION SIN IMAGEN Y PRESENTACION CON IMAGEN PERO NO ARCHIVOS*/
						BEGIN
							/*ELIMINAR PRESENTACION CON IMAGEN*/
							DELETE img 
								FROM ir_product_lang_presentation_image_lang p_la_pre_img_l
								INNER JOIN ir_product_lang_presentation p_l_pre
									ON p_la_pre_img_l.id_product_lang_presentation=p_l_pre.id_product_lang_presentation
								INNER JOIN ir_product_lang p_l
									ON p_l.id_product_lang=p_l_pre.id_product_lang
								INNER JOIN ir_image_lang img_l
									ON img_l.id_image_lang=p_la_pre_img_l.id_image_lang
								INNER JOIN ir_image img
									ON img.id_image=img_l.id_image
										WHERE p_l.id_product = ID_P;

							/*ELIMINAR PORTADAS Y/O GENERALES Y PRODUCTO*/
							DELETE img, p
								FROM ir_product_lang_image_lang p_l_img_l
								INNER JOIN ir_product_lang p_l 
									ON p_l_img_l.id_product_lang=p_l.id_product_lang
								INNER JOIN ir_product p
									ON p.id_product=p_l.id_product
								INNER JOIN ir_image_lang img_l
									ON img_l.id_image_lang=p_l_img_l.id_image_lang
								INNER JOIN ir_image img
									ON img.id_image=img_l.id_image
									WHERE p_l.id_product = ID_P;

							SELECT 4 AS ERRNO;
						END;
					END IF;
				ELSE 
					/*TIENE PORTADA, PRESENTACION SIN IMAGEN PERO NO PRESENTACION CON IMAGEN NI ARCHIVOS*/
					BEGIN

						/*ELIMINAR PORTADAS Y/O GENERALES Y BLOG*/
						DELETE img, p
							FROM ir_product_lang_image_lang p_l_img_l
							INNER JOIN ir_product_lang p_l 
								ON p_l_img_l.id_product_lang=p_l.id_product_lang
							INNER JOIN ir_product p
								ON p.id_product=p_l.id_product
							INNER JOIN ir_image_lang img_l
								ON img_l.id_image_lang=p_l_img_l.id_image_lang
							INNER JOIN ir_image img
								ON img.id_image=img_l.id_image
									WHERE p_l.id_product = ID_P;

						SELECT 3 AS ERRNO;
					END;
				END IF;
			ELSE
				/*SOLO TIENE PORTADA REGISTRADA*/
				BEGIN
					/*ELIMINAR PORTADAS Y/O GENERALES Y PRODUCTO*/
					DELETE img, p
						FROM ir_product_lang_image_lang p_l_img_l
						INNER JOIN ir_product_lang p_l 
							ON p_l_img_l.id_product_lang=p_l.id_product_lang
						INNER JOIN ir_product p
							ON p.id_product=p_l.id_product
						INNER JOIN ir_image_lang img_l
							ON img_l.id_image_lang=p_l_img_l.id_image_lang
						INNER JOIN ir_image img
							ON img.id_image=img_l.id_image
								WHERE p_l.id_product = ID_P;


					SELECT 6 AS ERRNO;
				END;
			END IF;
		ELSE
			/*TIENE PRESENTACION SIN IMAGEN PERO NO PORTADA*/
			IF EXISTS(SELECT 5 AS ERRNO
					FROM ir_product_lang_presentation p_l_pre
					INNER JOIN ir_product_lang p_l 
						ON p_l.id_product_lang=p_l_pre.id_product_lang
							WHERE p_l.id_product = ID_P) THEN

				/*TIENE PRESENTACION CON IMAGEN REGISTRADAS*/
				IF EXISTS(SELECT 5 AS ERRNO
						FROM ir_product_lang_presentation_image_lang p_la_pre_img
						INNER JOIN ir_product_lang_presentation p_l_pre
							ON p_la_pre_img.id_product_lang_presentation=p_l_pre.id_product_lang_presentation
						INNER JOIN ir_product_lang p_l
							ON p_l.id_product_lang=p_l_pre.id_product_lang
								WHERE p_l.id_product = ID_P) THEN

					/*TIENE ARCHIVOS REGISTRADOS*/
					IF EXISTS(SELECT 5 AS ERRNO
							FROM ir_product_lang_presentation_lang_file_lang p_la_pre_la_fi_l
							INNER JOIN ir_product_lang_presentation_lang p_l_pre_l
								ON p_la_pre_la_fi_l.id_product_lang_presentation_lang=p_l_pre_l.id_product_lang_presentation_lang
							INNER JOIN ir_product_lang_presentation p_l_pre
								ON p_l_pre.id_product_lang_presentation=p_l_pre_l.id_product_lang_presentation
							INNER JOIN ir_product_lang p_l
								ON p_l.id_product_lang=p_l_pre.id_product_lang
									WHERE p_l.id_product = ID_P) THEN

							/*TIENE PRESENTACION SIN IMAGEN, PRESENTACION CON IMAGEN Y ARCHIVOS PERO NO PORTADA*/
							BEGIN
								/*ELIMINAR ARCHIVOS*/
								DELETE f
									FROM ir_product_lang_presentation_lang_file_lang p_la_pre_la_fi_l
									INNER JOIN ir_product_lang_presentation_lang p_l_pre_l
										ON p_la_pre_la_fi_l.id_product_lang_presentation_lang=p_l_pre_l.id_product_lang_presentation_lang
									INNER JOIN ir_file_lang f_l
										ON f_l.id_file_lang=p_la_pre_la_fi_l.id_file_lang
									INNER JOIN ir_file f
										ON f.id_file=f_l.id_file
									INNER JOIN ir_product_lang_presentation p_l_pre
										ON p_l_pre.id_product_lang_presentation=p_l_pre_l.id_product_lang_presentation
									INNER JOIN ir_product_lang p_l
										ON p_l.id_product_lang=p_l_pre.id_product_lang
											WHERE p_l.id_product = ID_P;

								/*PRESENTACION CON IMAGEN*/
								DELETE img 
									FROM ir_product_lang_presentation_image_lang p_la_pre_img_l
									INNER JOIN ir_product_lang_presentation p_l_pre
										ON p_la_pre_img_l.id_product_lang_presentation=p_l_pre.id_product_lang_presentation
									INNER JOIN ir_product_lang p_l
										ON p_l.id_product_lang=p_l_pre.id_product_lang
									INNER JOIN ir_image_lang img_l
										ON img_l.id_image_lang=p_la_pre_img_l.id_image_lang
									INNER JOIN ir_image img
										ON img.id_image=img_l.id_image
											WHERE p_l.id_product = ID_P;

								/*ELIMINAR PRODUCTO*/
								DELETE FROM ir_product WHERE id_product = ID_P;
	
								SELECT 9 AS ERRNO;
							END;
					ELSE
						/*TIENE PRESENTACION SIN IMAGEN, PRESENTACION CON IMAGEN PERO NO PORTADA NI ARCHIVOS*/
						BEGIN
							/*ELIMINAR PRESENTACION CON IMAGEN*/
							DELETE img 
								FROM ir_product_lang_presentation_image_lang p_la_pre_img_l
								INNER JOIN ir_product_lang_presentation p_l_pre
									ON p_la_pre_img_l.id_product_lang_presentation=p_l_pre.id_product_lang_presentation
								INNER JOIN ir_product_lang p_l
									ON p_l.id_product_lang=p_l_pre.id_product_lang
								INNER JOIN ir_image_lang img_l
									ON img_l.id_image_lang=p_la_pre_img_l.id_image_lang
								INNER JOIN ir_image img
									ON img.id_image=img_l.id_image
										WHERE p_l.id_product = ID_P;

							/*ELIMINAR PRODUCTO*/
							DELETE FROM ir_product WHERE id_product = ID_P;

							SELECT 8 AS ERRNO;
						END;
					END IF;
				ELSE 
					/*TIENE PRESENTACION SIN IMAGEN PERO NO PORTADA, PRESENTACION CON IMAGEN, NI ARCHIVOS*/
					BEGIN

						/*ELIMINAR PRODUCTO*/
						DELETE FROM ir_product WHERE id_product = ID_P;

						SELECT 7 AS ERRNO;
					END;
				END IF;
			ELSE
				/*SOLO TIENE EL REGISTRO BASICO*/
				BEGIN
					DELETE FROM ir_product WHERE id_product = ID_P;

					SELECT 2 AS ERRNO;
				END;
			END IF;
		END IF;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteUser` (IN `ID_U` INT)   BEGIN
	DELETE FROM ir_user WHERE id_user = ID_U;
	
	/* Comprobar si el DELETE afectó a alguna fila */
	IF ROW_COUNT() > 0 THEN
		/* El usuario existía y fue eliminado */
		SELECT 2 AS ERRNO;
	ELSE
		/* El usuario no existía (ninguna fila fue eliminada) */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteUserCustomize` (IN `ID_U_C` INT)   BEGIN
	DELETE FROM ir_user_customize
	WHERE id_user_customize = ID_U_C;
	
	/* Comprobar si el DELETE afectó a alguna fila */
	IF ROW_COUNT() > 0 THEN
		/* El registro existía y fue eliminado */
		SELECT 2 AS ERRNO;
	ELSE
		/* El registro no existía (ninguna fila fue eliminada) */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteUserSocialNetwork` (IN `ID_U_SM` INT)   BEGIN
	DELETE FROM ir_user_social_media
	WHERE id_user_social_media = ID_U_SM;
	
	/* Comprobar si el DELETE afectó a alguna fila */
	IF ROW_COUNT() > 0 THEN
		/* El registro existía y fue eliminado */
		SELECT 2 AS ERRNO;
	ELSE
		/*  El registro no existía (ninguna fila fue eliminada) */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getNewProductId` ()   BEGIN
	DECLARE return_ID INT DEFAULT 0;

	IF EXISTS(SELECT 2 AS ERRNO FROM ir_product) THEN
		BEGIN
			SET return_ID = (SELECT MAX(id_product) FROM ir_product) + 1;

			SELECT return_ID AS ID_PRODUCT;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ID_PRODUCT;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getTotalProducts` ()   BEGIN
	SELECT COUNT(id_product) AS TOTAL_PRODUCTS
		FROM ir_product;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getTotalSocialNetworksByUserId` (IN `ID_U` INT)   BEGIN
	SELECT count(*) AS totalSocialNetworksByUserId
		FROM ir_user_social_media
			WHERE id_user = ID_U;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getTotalUsersByRoleId` (IN `ID_R` INT)   BEGIN
	SELECT COUNT(*) AS TOTAL_USERS
		FROM ir_user
			WHERE id_role = ID_R;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `leaveAsMainPresentationProduct` (IN `ID_P_LA_PRE_IMG_LA` INT)   BEGIN

	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_product_lang_presentation_image_lang
				WHERE id_product_lang_presentation_image_lang = ID_P_LA_PRE_IMG_LA) THEN
		BEGIN
			UPDATE ir_product_lang_presentation_image_lang
			SET	s_main_product_lang_presentation_image_lang 		= 1
					WHERE id_product_lang_presentation_image_lang 	= ID_P_LA_PRE_IMG_LA;

			SELECT 2 AS ERRNO;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `leaveAsMainProduct` (IN `ID_P_LA` INT, IN `ID_IMG_LA_V` INT)   BEGIN
	IF EXISTS(SELECT 3 AS ERRNO FROM ir_product_lang_image_lang WHERE id_product_lang = ID_P_LA) THEN
		IF EXISTS(SELECT 3 AS ERRNO 
				FROM ir_image_lang_version 
					WHERE id_image_lang_version = ID_IMG_LA_V) THEN
			BEGIN
				/*PRIMERO VAMOS A DEJAR TODAS LAS IMAGENES DE ESTE PRODUCTO SEGUN EL ISO COMO FOTO GENERAL Y NO PORTADA*/
				UPDATE ir_product_lang_image_lang p_l_img_l
					INNER JOIN ir_image_lang_version img_l_v 
						ON p_l_img_l.id_image_lang=img_l_v.id_image_lang

				SET img_l_v.s_main_image_lang_version 	= 0
					WHERE p_l_img_l.id_product_lang	= ID_P_LA;

				/*POR ULTIMO DEJAMOS SOLO LA PORTADA SUGERIDA POR EL USUARIO*/
				UPDATE ir_image_lang_version
				SET s_main_image_lang_version 		= 1
					WHERE id_image_lang_version 	= ID_IMG_LA_V;

				SELECT 3 AS ERRNO;
			END;
		ELSE	
			/* NO EXISTE EL ID_IMG_LA_V */
			BEGIN	
				SELECT 2 AS ERRNO;
			END;
		END IF;
	ELSE
		/* NO EXISTE EL ID_P_LA */
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `logIn` (IN `E_U` VARCHAR(50), IN `TI` VARCHAR(30))   BEGIN
	DECLARE TOTAL_ATTEMPTS,TOTAL_USERS,USER_ID INT DEFAULT 0;

	/* 1. VERIFICAR UNICIDAD DE USUARIO */
	SET TOTAL_USERS = (SELECT COUNT(u1.id_user)
				FROM ir_user u1
					WHERE u1.email_user = CONVERT(E_U using utf8mb4) collate utf8mb4_unicode_ci
					OR u1.username_website = CONVERT(E_U using utf8mb4) collate utf8mb4_unicode_ci);

	/* EXISTE EL CORREO O USUARIO Y NO ESTA DUPLICADO */
	IF (TOTAL_USERS = 1) THEN
	
		/* 2. OBTENER ID DE USUARIO SI ESTÁ ACTIVO */
		SET USER_ID = (SELECT u1.id_user
					FROM ir_user u1
						WHERE (u1.email_user = CONVERT(E_U using utf8mb4) collate utf8mb4_unicode_ci
						OR u1.username_website = CONVERT(E_U using utf8mb4) collate utf8mb4_unicode_ci)
						AND u1.s_user = 1
							LIMIT 0,1);

		/* EL USUARIO ESTA ACTIVO (USER_ID > 0) */
		IF (USER_ID > 0) THEN
		
			/* 3. TOTAL DE INTENTOS */
			SET TOTAL_ATTEMPTS = (SELECT COUNT(i.time_session_attempt)
							FROM ir_user u
							INNER JOIN ir_session_attempt i ON i.id_user=u.id_user
								WHERE u.id_user = USER_ID
								AND i.time_session_attempt > TI);

			/* NO EXCEDIO EL LIMITE DE INTENTOS */
			IF (TOTAL_ATTEMPTS < 6) THEN
			
				/* 4. RETORNAR DATOS Y ACTUALIZAR SESIÓN */
				BEGIN
					/* MODIFICAR ULTIMA SESION */
					UPDATE ir_user
						SET last_session_user = CURRENT_TIMESTAMP
							WHERE id_user = USER_ID;
					
					/* RETORNAR DATOS DE USUARIO */
					SELECT u.id_user,u.password_user,u.cp_user,u.salt_user,r.id_role,u.name_user,u.gender_user,5 AS ERRNO
						FROM ir_role r 
						INNER JOIN ir_user u ON r.id_role=u.id_role
							WHERE id_user = USER_ID
								LIMIT 0,1;
				END;
			ELSE
				/* Limite de intentos excedido */
				SELECT 3 AS ERRNO;
			END IF;
		ELSE
			/* Usuario no activo (USER_ID = 0) */
			SELECT 2 AS ERRNO;
		END IF;
	ELSE
		/* Usuario no existe o está duplicado (TOTAL_USERS != 1) */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `prefixLangByIdLang` (IN `ID_LA` INT)   BEGIN
	SELECT id_lang,lang,iso_code,2 AS ERRNO
		FROM ir_lang
		WHERE s_lang = 1
		AND id_lang = ID_LA
			LIMIT 0,1;
	
	/* Comprobar si la consulta anterior devolvió alguna fila.
	Si FOUND_ROWS() es 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		/* No se encontraron filas, devolver el código de error 1. */
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (incluyendo ERRNO 2) ya fueron 
	enviados al cliente por el primer SELECT.
	*/
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `recoverPasswordByEmailUser` (IN `E_U` VARCHAR(50), IN `PA` CHAR(128), IN `SA` CHAR(128))   BEGIN
	/* 1. MODIFICAR CONTRASEÑA DIRECTAMENTE.*/
	UPDATE ir_user
	SET password_user = PA,
	    salt_user = SA
	WHERE email_user = CONVERT(E_U using utf8mb4) collate utf8mb4_unicode_ci;

	/* 2. Comprobar si la actualización afectó a alguna fila */
	IF ROW_COUNT() > 0 THEN
		/* Éxito: El usuario fue encontrado y actualizado.*/
		SELECT id_user,CONCAT(name_user,' ',last_name_user) AS NOMBRE_COMPLETO, 2 AS ERRNO
			FROM ir_user
				WHERE email_user = CONVERT(E_U using utf8mb4) collate utf8mb4_unicode_ci
					LIMIT 0,1;
	ELSE
		/* Falla: No se encontró ningún usuario con ese email */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerAttemptLogin` (IN `E_U` VARCHAR(50), IN `TI` VARCHAR(30))   BEGIN
	DECLARE USER_ID INT DEFAULT 0;

	SET USER_ID = (SELECT id_user 
				FROM ir_user 
					WHERE email_user = CONVERT(E_U using utf8mb4) collate utf8mb4_unicode_ci
					OR username_website = CONVERT(E_U using utf8mb4) collate utf8mb4_unicode_ci);
	
	/* Si se encontró un usuario (y solo uno), se registra el intento */
	IF (USER_ID > 0) THEN
		INSERT INTO ir_session_attempt
		VALUE(NULL,USER_ID,TI);
	END IF;

	SELECT 1 AS ERRNO;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerAttribute` (IN `TI` VARCHAR(70), IN `PA` INT, IN `ID_U` INT)   BEGIN
	DECLARE ID_ATTR INT DEFAULT 0;

	DECLARE done INT DEFAULT FALSE;
	DECLARE langId INT;
	DECLARE cur1 CURSOR FOR SELECT id_lang FROM ir_lang WHERE s_lang = 1;
   	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
	
	IF EXISTS(SELECT 3 AS ERRNO FROM ir_user WHERE id_user = ID_U) THEN
		IF NOT EXISTS(SELECT 3 AS ERRNO 
					FROM ir_attribute a
					INNER JOIN ir_attribute_lang a_l 
						ON a.id_attribute=a_l.id_attribute
						WHERE a_l.title_attribute_lang 	= CONVERT(TI using utf8mb4) collate utf8mb4_unicode_ci
						AND a.parent_id_attribute 	= PA
						AND a.id_user 			= ID_U) THEN
			BEGIN
				INSERT INTO ir_attribute
				VALUES(NULL,ID_U,PA,0,1);

				SET ID_ATTR = (SELECT @@IDENTITY);

				OPEN cur1;

      					read_loop: LOOP
         					FETCH cur1 INTO langId;
         
         					IF done THEN 
            						LEAVE read_loop;
         					END IF;

         					INSERT INTO ir_attribute_lang(id_attribute_lang,id_lang,id_attribute,title_attribute_lang)
						VALUES(NULL,langId,ID_ATTR,TI);

      					END LOOP;

   				CLOSE cur1;
				
				SELECT 3 AS ERRNO;
			END;	
		ELSE
			/*EL TITULO YA EXITE REGISTRADO*/
			BEGIN
				SELECT 2 AS ERRNO;
			END;
		END IF;
	ELSE
		/*ID USER NO EXISTE*/
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerBasicInformationProduct` (IN `ID_P` INT, IN `ID_TA` INT, IN `ID_CU` INT, IN `TI` VARCHAR(150), IN `FRIENDLY` VARCHAR(200))   BEGIN
	DECLARE ID_P_LA INT DEFAULT 0;

	DECLARE done INT DEFAULT FALSE;
	DECLARE langId INT;
	DECLARE cur1 CURSOR FOR SELECT id_lang FROM ir_lang WHERE s_lang = 1;
   	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	OPEN cur1;

      	read_loop: LOOP
         	FETCH cur1 INTO langId;
         
         	IF done THEN 
            		LEAVE read_loop;
         	END IF;

         	/*REGISTRAR LA INFORMACION DE PRODUCTO SI NO EXISTE*/
		IF NOT EXISTS(SELECT 1 AS ERRNO 
					FROM ir_product_lang
						WHERE id_product 	= ID_P
						AND id_lang 		= langId) THEN
			BEGIN
				INSERT INTO ir_product_lang(id_product_lang,id_lang,id_product,id_tax_rule,id_type_of_currency,title_product_lang,friendly_url_product_lang,meta_title_product_lang)
				VALUE(NULL,langId,ID_P,ID_TA,ID_CU,TI,FRIENDLY,TI);
			END;
		END IF;

      	END LOOP;

   	CLOSE cur1;
	
	call showAllProductsLangByProductId(ID_P);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerCategory` (IN `HE` VARCHAR(30), IN `TI` VARCHAR(70), IN `SUB_TI` VARCHAR(45), IN `DE_SM` VARCHAR(100), IN `DE_LA` TEXT, IN `PA` INT, IN `ID_U` INT)   BEGIN
	DECLARE ID_C INT DEFAULT 0;

	/* Manejador de errores para revertir la transacción */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; /* Error genérico de SQL */
	END;

	/* 1. ID USER NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_user WHERE id_user = ID_U LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. EL TITULO YA EXITE REGISTRADO */
	ELSEIF EXISTS(SELECT 1 
				FROM ir_category c 
				INNER JOIN ir_category_lang c_l 
					ON c.id_category=c_l.id_category
				WHERE c_l.title_category_lang = CONVERT(TI using utf8mb4) collate utf8mb4_unicode_ci
					AND c.parent_id = PA
					AND c.id_user = ID_U
				LIMIT 1) THEN
		SELECT 2 AS ERRNO;

	/* 3. Proceder con la inserción */
	ELSE
		/* Iniciar transacción */
		START TRANSACTION;

		INSERT INTO ir_category(id_category,id_user,parent_id,color_hexadecimal_category)
		VALUES(NULL,ID_U,PA,HE);

		SET ID_C = LAST_INSERT_ID();
		
		INSERT INTO ir_category_lang(id_category_lang,id_lang,id_category,title_category_lang,subtitle_category_lang,description_small_category_lang,description_large_category_lang)
		SELECT NULL, id_lang, ID_C, TI, SUB_TI, DE_SM, DE_LA
		FROM ir_lang
		WHERE s_lang = 1;

		/* Confirmar transacción */
		COMMIT;

		SELECT 3 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerCustomization` ()   BEGIN
	/* 1. Insertar el registro */
	INSERT INTO ir_customize
	VALUES(NULL,1);

	/* 2. Devolver el ID recién insertado */
	SELECT LAST_INSERT_ID() AS ID_C;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerCustomizationLang` (IN `ID_C` INT, IN `ID_LA` INT, IN `ID_U` INT, IN `CO` VARCHAR(10), IN `TXT_1` VARCHAR(100), IN `IMG` VARCHAR(70))   BEGIN
	/* 1. EL ID CUSTOMIZE NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_customize WHERE id_customize = ID_C LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. EL ID LANG NO EXISTE */
	ELSEIF NOT EXISTS(SELECT 1 FROM ir_lang WHERE id_lang = ID_LA LIMIT 1) THEN
		SELECT 2 AS ERRNO;
		
	/* 3. Todas las validaciones pasaron */
	ELSE
		INSERT INTO ir_customize_lang
		VALUES(NULL,ID_LA,ID_C,CONCAT('Fondo usuario',' ',ID_U),IMG,'',CO,TXT_1);

		SELECT 3 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerGalleryUser` (IN `ID_T_IMG` INT, IN `FO` VARCHAR(15), IN `SI` INT)   BEGIN
	DECLARE ID_IMG INT DEFAULT 0;
	
	/* 1. Comprobar si el tipo de imagen existe */
	IF EXISTS(SELECT 1 FROM ir_type_image WHERE id_type_image = ID_T_IMG LIMIT 1) THEN
		
		/* 2. Insertar la imagen */
		INSERT INTO ir_image
		VALUES(NULL,ID_T_IMG,0,0,FO,SI,0,0,1); /* Estandarizado a VALUES */

		SET ID_IMG = LAST_INSERT_ID(); /* Estandarizado */

		/* 3. Devolver éxito */
		SELECT ID_IMG, 3 AS ERRNO;
	
	ELSE
		/* El tipo de imagen no existe */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerGeneralUserFront` (IN `NO` VARCHAR(50), IN `L_N` VARCHAR(50), IN `LA_TE` VARCHAR(7), IN `TE` VARCHAR(25), IN `LA_CE` VARCHAR(7), IN `CE` VARCHAR(25), IN `E` VARCHAR(50), IN `U_NA` VARCHAR(20), IN `PA` CHAR(128), IN `SA` CHAR(128))   BEGIN
	DECLARE ID_U INT DEFAULT 0;
	DECLARE U_TIME DATETIME;
	
	/* Manejador de errores para revertir la transacción */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; /* Error genérico de SQL */
	END;
	
	/* Aplanamiento de lógica (Guard Clauses) */

	/* 1. YA EXISTE REGISTRADO EL CORREO */
	IF EXISTS(SELECT 1 FROM ir_user WHERE email_user = CONVERT(E using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. YA EXISTE REGISTRADO EL USERNAME */
	ELSEIF EXISTS(SELECT 1 FROM ir_user WHERE username_website = CONVERT(U_NA using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1) THEN
		SELECT 2 AS ERRNO;

	/* 3. ÉXITO: Todas las validaciones pasaron, proceder con el registro */
	ELSE
		SET U_TIME = CURRENT_TIMESTAMP;

		/* Iniciar transacción para integridad de datos */
		START TRANSACTION;

		INSERT INTO ir_user(id_user,id_role,name_user,last_name_user,gender_user,lada_telephone_user,telephone_user,lada_cell_phone_user,cell_phone_user,email_user,profile_photo_user,username_website,password_user,salt_user,s_user,registration_date_user,last_session_user)
		VALUES(NULL,3,NO,L_N,'U',LA_TE,TE,LA_CE,CE,E,'profile.png',U_NA,PA,SA,1,U_TIME,U_TIME);
					
		SET ID_U = LAST_INSERT_ID(); /* Estandarizado desde @@IDENTITY */

		INSERT INTO ir_user_customize
		VALUES(NULL,1,ID_U,U_TIME);

		/* Confirmar transacción */
		COMMIT;

		SELECT 3 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerImage` (IN `ID_T_IMG` INT, IN `ID_M` INT, IN `WI` INT, IN `HE` INT, IN `FO` VARCHAR(15), IN `SI` INT)   BEGIN
	DECLARE ID_IMG INT DEFAULT 0;

	/* Manejador de errores para revertir la transacción */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; 
	END;

	/* 1. EL TIPO DE IMAGEN NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_type_image WHERE id_type_image = ID_T_IMG LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. EL MENU NO EXISTE */
	ELSEIF NOT EXISTS(SELECT 1 FROM ir_menu WHERE id_menu = ID_M LIMIT 1) THEN
		SELECT 2 AS ERRNO;

	/* 3. Todas las validaciones pasaron */
	ELSE
		/* Iniciar transacción para integridad de datos */
		START TRANSACTION;

		INSERT INTO ir_image
		VALUES(NULL,ID_T_IMG,WI,HE,FO,SI,0,0,0);
			
		SET ID_IMG = LAST_INSERT_ID();
			
		INSERT INTO ir_menu_image
		VALUES(NULL,ID_M,ID_IMG);

		/* Confirmar transacción */
		COMMIT;

		SELECT ID_IMG, 4 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerImageCategory` (IN `ID_C` INT, IN `ID_IMG_SE` INT, IN `ID_T_IMG` INT, IN `FO` VARCHAR(15), IN `SI` INT)   BEGIN
	DECLARE ID_IMG,TOTAL_SECTION,TOTAL_LANG INT DEFAULT 0;

	/* 1. OBTENER TOTAL DE SECCIONES YA REGISTRADAS */
	SET TOTAL_SECTION = (SELECT COUNT(*)
					FROM ir_category_lang c_l 
					INNER JOIN ir_category_lang_image_lang c_l_img_l 
						ON c_l.id_category_lang=c_l_img_l.id_category_lang
					INNER JOIN ir_image_section_lang img_s_l
						ON img_s_l.id_image_section_lang=c_l_img_l.id_image_section_lang
					WHERE c_l.id_category = ID_C
						AND img_s_l.id_image_section = ID_IMG_SE);

	/*VALIDAR EL TOTAL DE IMAGEN SECCION REGISTRADO EN LOS IDIOMAS*/
	IF (TOTAL_SECTION > 0) THEN
		
		/* 2. YA EXISTE EN ALGUNOS IDIOMAS */
		SET TOTAL_LANG = (SELECT COUNT(id_lang) FROM ir_lang);

		IF (TOTAL_SECTION < TOTAL_LANG) THEN
			/* 2a. OBTENER EL ID_IMG QUE YA SE ENCUENTRA REGISTRADO */
			/* (Para que el front-end añada un nuevo idioma a este ID_IMG) */
			
			SET ID_IMG = (SELECT img_l.id_image
						FROM ir_category_lang c_l 
						INNER JOIN ir_category_lang_image_lang c_l_img_l 
							ON c_l.id_category_lang=c_l_img_l.id_category_lang
						INNER JOIN ir_image_section_lang img_s_l
							ON img_s_l.id_image_section_lang=c_l_img_l.id_image_section_lang
						INNER JOIN ir_image_lang img_l
							ON img_l.id_image_lang=c_l_img_l.id_image_lang
						WHERE c_l.id_category = ID_C
							AND img_s_l.id_image_section = ID_IMG_SE
						LIMIT 0,1);

			SELECT ID_IMG, 4 AS ERRNO;
		ELSE
			/* 2b. ESTA CATEGORIA YA CUENTA CON LA SECCION EN TODOS LOS IDIOMAS*/
			SELECT 3 AS ERRNO;
		END IF;
	ELSE
		/* 3. REGISTRA DESDE 0 LA IMAGEN */
		IF NOT EXISTS(SELECT 1 FROM ir_type_image WHERE id_type_image = ID_T_IMG LIMIT 1) THEN
			/* (ERRNO 1) ID TYPE IMAGEN NO EXISTE */
			SELECT 1 AS ERRNO;
		ELSE
			INSERT INTO ir_image
			VALUES(NULL,ID_T_IMG,0,0,FO,SI,0,0,1);

			SET ID_IMG = LAST_INSERT_ID();

			SELECT ID_IMG, 4 AS ERRNO;
		END IF;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerImageProduct` (IN `ID_P` INT, IN `ID_U` INT, IN `ID_T_IMG` INT, IN `FO` VARCHAR(15), IN `SI` INT)   BEGIN
	DECLARE ID_IMG INT DEFAULT 0;
	
	IF EXISTS(SELECT 5 AS CORRECT FROM ir_user WHERE id_user = ID_U) THEN
		IF EXISTS(SELECT 5 AS CORRECT FROM ir_type_image WHERE id_type_image = ID_T_IMG) THEN

			/*REGISTRAR LA INFORMACION DE PRODUCTO SI NO EXISTE*/
			IF NOT EXISTS(SELECT 5 AS CORRECT FROM ir_product WHERE id_product = ID_P) THEN
				BEGIN
					/*
					id_type_product
						1 = Producto
						2 = Accesorio
					*/
					INSERT INTO ir_product(id_product,id_user,id_type_product)
					VALUE(ID_P,ID_U,1);
				END;
			END IF;

			INSERT INTO ir_image(id_image,id_type_image,format_image,size_image,s_image)
			VALUE(NULL,ID_T_IMG,FO,SI,1);

			SET ID_IMG = (SELECT @@IDENTITY);

			IF EXISTS(SELECT 5 AS CORRECT FROM ir_image WHERE id_image = ID_IMG) THEN
				BEGIN
					SELECT ID_IMG,5 AS ERRNO;
				END;
			ELSE
				/* EL ID_IMG NO EXISTE */
				BEGIN
					DELETE FROM ir_product WHERE id_product = ID_P;

					SELECT 4 AS ERRNO;
				END;
			END IF;
		ELSE
			/* EL ID_T_IMG NO EXISTE */
			BEGIN
				SELECT 2 AS ERRNO;
			END;
		END IF;
	ELSE
		/* EL ID_U NO EXISTE */
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerImageVersion` (IN `ID_IMG_LA` INT, IN `ID_TY_VE` INT, IN `IMG` VARCHAR(70))   BEGIN
	DECLARE v_is_main TINYINT DEFAULT 0;

	/* 1. EL ID IMG_LANG NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_image_lang WHERE id_image_lang = ID_IMG_LA LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. EL ID TYPE_VERSION NO EXISTE */
	ELSEIF NOT EXISTS(SELECT 1 FROM ir_type_version WHERE id_type_version = ID_TY_VE LIMIT 1) THEN
		SELECT 2 AS ERRNO;
		
	/* 3. YA EXISTE LA VERSION */
	ELSEIF EXISTS(SELECT 1
				  FROM ir_image_lang_version
				  WHERE id_image_lang = ID_IMG_LA
					AND id_type_version = ID_TY_VE
				  LIMIT 1) THEN
		SELECT 3 AS ERRNO;
		
	/* 4. Proceder con la inserción */
	ELSE
		/* ID_TY_VE = 1 es PORTADA (s_main_image_lang_version = 1) */
		IF(ID_TY_VE = 1) THEN
			SET v_is_main = 1;
		END IF;

		INSERT INTO ir_image_lang_version
		VALUES(NULL, ID_IMG_LA, v_is_main, ID_TY_VE, IMG);

		SELECT 4 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerInformationGalleryUser` (IN `ID_U` INT, IN `ID_IMG` INT, IN `ID_LA` INT, IN `IMG` VARCHAR(70))   BEGIN
	DECLARE ID_IMG_LA INT DEFAULT 0;

	/* Manejador de errores para revertir la transacción */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; /* Error genérico de SQL */
	END;

	/* 1. Comprobar si la imagen 'padre' existe */
	IF NOT EXISTS(SELECT 1 FROM ir_image WHERE id_image = ID_IMG LIMIT 1) THEN
		/* No existe la imagen 'padre' */
		SELECT 1 AS ERRNO;
	ELSE
		/* Iniciar transacción para integridad de datos */
		START TRANSACTION;

		INSERT INTO ir_image_lang
		VALUES(NULL,ID_LA,ID_IMG,CONCAT('Galería ',ID_IMG),NULL,NULL,NULL,NULL,NULL,CONCAT('Galería ',ID_IMG),NULL,NULL,NULL,NULL,NULL,CURRENT_TIMESTAMP,1);

		SET ID_IMG_LA = LAST_INSERT_ID();

		INSERT INTO ir_user_gallery_image_lang
		VALUES(NULL,ID_U,ID_IMG_LA);

		INSERT INTO ir_image_lang_version
		VALUES(NULL,ID_IMG_LA,0,1,IMG);

		/* Confirmar transacción */
		COMMIT;

		SELECT 3 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerInformationImage` (IN `ID_IMG` INT, IN `ID_LA` INT, IN `ID_T_IMG` INT, IN `ID_TY_VE` INT, IN `TI` VARCHAR(70), IN `SUB_TI` VARCHAR(45), IN `DE_SM` VARCHAR(400), IN `DE_LA` TEXT, IN `TI_LI` VARCHAR(100), IN `LI` VARCHAR(255), IN `ALT` VARCHAR(100), IN `BGC` VARCHAR(30), IN `BGCD` TEXT, IN `BGR` VARCHAR(15), IN `BGP` VARCHAR(20), IN `BGS` VARCHAR(15), IN `IMG` VARCHAR(70))   BEGIN
	DECLARE ID_IMG_LA INT DEFAULT 0;

	/* Manejador de errores para revertir la transacción */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT 5 AS ERRNO; 
	END;

	/* 1. ID LANG NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_lang WHERE id_lang = ID_LA LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. ID_IMG NO EXISTE */
	ELSEIF NOT EXISTS(SELECT 1 FROM ir_image WHERE id_image = ID_IMG LIMIT 1) THEN
		SELECT 2 AS ERRNO;
		
	/* 3. ID TY VERSION NO EXISTE */
	ELSEIF NOT EXISTS(SELECT 1 FROM ir_type_version WHERE id_type_version = ID_TY_VE LIMIT 1) THEN
		SELECT 3 AS ERRNO;
		
	/* 4. YA EXISTE REGISTRADA UNA IMAGEN CON ESE IDIOMA */
	ELSEIF EXISTS(SELECT 1 
				  FROM ir_image_lang
				  WHERE id_image = ID_IMG AND id_lang = ID_LA
				  LIMIT 1) THEN
		SELECT 4 AS ERRNO;
	
	/* 5. Todas las validaciones pasaron */
	ELSE
		/* Iniciar transacción */
		START TRANSACTION;

		INSERT INTO ir_image_lang
		VALUES(NULL,ID_LA,ID_IMG,TI,SUB_TI,DE_SM,DE_LA,TI_LI,LI,ALT,BGC,BGCD,BGR,BGP,BGS,CURRENT_TIMESTAMP,1);
		
		SET ID_IMG_LA = LAST_INSERT_ID();

		/* 6. YA EXISTE REGISTRADA UNA VERSIÓN */
		IF EXISTS(SELECT 1 
				  FROM ir_image_lang_version
				  WHERE id_image_lang = ID_IMG_LA
				    AND id_type_version = ID_TY_VE
				  LIMIT 1) THEN
			ROLLBACK;
			SELECT 6 AS ERRNO;
		
		/* 7. Insertar versión y slider */
		ELSE
			INSERT INTO ir_image_lang_version
			VALUES(NULL,ID_IMG_LA,1,ID_TY_VE,IMG);
			
			IF (ID_T_IMG = 6) THEN
				INSERT INTO ir_slider
				VALUES(NULL,ID_IMG_LA);
			END IF;

			/* Confirmar transacción */
			COMMIT;
			SELECT 7 AS ERRNO;
		END IF;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerInformationImageLangCategory` (IN `ID_C_LA` INT, IN `ID_LA` INT, IN `ID_IMG` INT, IN `ID_IMG_SE` INT, IN `TI` VARCHAR(70), IN `IMG` VARCHAR(70))   BEGIN
	DECLARE ID_IMG_LA, ID_IMG_SE_LA INT DEFAULT 0;

	/* Manejador de errores para revertir la transacción */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT 3 AS ERRNO; 
	END;
					
	/* 1. Obtener el ID de la sección del idioma */
	SET ID_IMG_SE_LA = (SELECT id_image_section_lang 
						FROM ir_image_section_lang 
						WHERE id_image_section = ID_IMG_SE AND id_lang = ID_LA);

	/* 2. QUE EXISTA LA SECCION DE LA IMAGEN (ERRNO 2) */
	IF ID_IMG_SE_LA IS NULL OR ID_IMG_SE_LA = 0 THEN
		SELECT 2 AS ERRNO;

	/* 3. EL REGISTRO YA EXISTE (ERRNO 1) */
	ELSEIF EXISTS(SELECT 1
			FROM ir_category_lang_image_lang 
			WHERE id_category_lang = ID_C_LA
				AND id_image_section_lang = ID_IMG_SE_LA
			LIMIT 1) THEN
		SELECT 1 AS ERRNO;

	/* 4. Proceder con la inserción */
	ELSE
		/* Iniciar transacción */
		START TRANSACTION;

		INSERT INTO ir_image_lang(id_image_lang,id_lang,id_image,title_image_lang,alt_image_lang,last_update_image_lang,s_image_lang_visible)
		VALUES(NULL,ID_LA,ID_IMG,TI,TI,CURRENT_TIMESTAMP,1);

		SET ID_IMG_LA = LAST_INSERT_ID();

		INSERT INTO ir_category_lang_image_lang
		VALUES(NULL,ID_C_LA,ID_IMG_SE_LA,ID_IMG_LA);

		INSERT INTO ir_image_lang_version
		VALUES(NULL,ID_IMG_LA,0,1,IMG);

		/* Confirmar transacción */
		COMMIT;

		SELECT 4 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerInformationImageProduct` (IN `ID_P_LA` INT, IN `ID_LA` INT, IN `ID_IMG` INT, IN `TI` VARCHAR(150), IN `ISO` VARCHAR(5), IN `IMG` VARCHAR(70))   BEGIN
	DECLARE ID_IMG_LA INT DEFAULT 0;
	DECLARE ID_IMG_LA_VER INT DEFAULT 0;
	DECLARE ID_P_LA_IMG_LA INT DEFAULT 0;
	DECLARE S_MAIN_IMG_LA_VER INT DEFAULT 0;
	
	INSERT INTO ir_image_lang(id_image_lang,id_lang,id_image,title_image_lang,alt_image_lang,last_update_image_lang,s_image_lang_visible)
	VALUE(NULL,ID_LA,ID_IMG,CONCAT(TI,' ',ISO),CONCAT(TI,' ',ISO),CURRENT_TIMESTAMP,1);

	SET ID_IMG_LA 	= (SELECT @@IDENTITY);

	/*DETERMINAR TIPO DE IMAGEN: PORTADA O NORMAL*/
	IF EXISTS(SELECT 1 AS ERRNO 
			FROM ir_product_lang_image_lang					
				WHERE id_product_lang = ID_P_LA) THEN
		BEGIN
			/*NORMAL*/
			INSERT INTO ir_image_lang_version
			VALUE(NULL,ID_IMG_LA,0,1,IMG);

			SET ID_IMG_LA_VER 	= (SELECT @@IDENTITY);
			SET S_MAIN_IMG_LA_VER 	= 0;
		END;
	ELSE
		BEGIN
			/*PORTADA*/
			INSERT INTO ir_image_lang_version
			VALUE(NULL,ID_IMG_LA,1,1,IMG);

			SET ID_IMG_LA_VER 	= (SELECT @@IDENTITY);
			SET S_MAIN_IMG_LA_VER 	= 1;
		END;
	END IF;	

	INSERT INTO ir_product_lang_image_lang
	VALUES(NULL,ID_P_LA,ID_IMG_LA);

	SET ID_P_LA_IMG_LA = (SELECT @@IDENTITY);
		
	SELECT ID_IMG_LA_VER,S_MAIN_IMG_LA_VER,ID_P_LA_IMG_LA,1 AS ERRNO;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerInformationProduct` (IN `ID_P` INT, IN `ID_U` INT, IN `ID_TA` INT, IN `ID_CU` INT, IN `TI` VARCHAR(150), IN `SUB_TI` VARCHAR(100), IN `PRE` DECIMAL(19,2), IN `BTN_PRE` VARCHAR(50), IN `COL_PRE` VARCHAR(20), IN `BG_COL` TEXT, IN `STOK` INT, IN `REF` VARCHAR(40), IN `FRIENDLY` VARCHAR(200), IN `GE_LI` VARCHAR(600), IN `BTN_GE_LI` VARCHAR(50), IN `DE_SM` TEXT, IN `DE_LA` TEXT, IN `ESPECI` TEXT, IN `CL_PR` VARCHAR(20), IN `CL_UN` VARCHAR(20), IN `ME_TI` VARCHAR(128), IN `ME_DESC` VARCHAR(255), IN `ME_KY` VARCHAR(2000))   BEGIN
	DECLARE done INT DEFAULT FALSE;
	DECLARE langId INT;
	DECLARE cur1 CURSOR FOR SELECT id_lang FROM ir_lang WHERE s_lang = 1;
   	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

	IF EXISTS(SELECT 4 AS ERRNO FROM ir_product WHERE id_product = ID_P) THEN
			
			/*EL TITULO DEL PRODUCTO NO EXISTE*/
			IF NOT EXISTS(SELECT 4 AS ERRNO 
					FROM ir_product p
					INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
						WHERE p_l.title_product_lang 	= CONVERT(TI using utf8mb4) collate utf8mb4_unicode_ci
						  AND p.id_user 		= ID_U
						  AND p_l.id_product 	       != ID_P) THEN
				OPEN cur1;

      				    read_loop: LOOP
         				FETCH cur1 INTO langId;
         
         				IF done THEN 
            					LEAVE read_loop;
         				END IF;

					/*DETERMINAR SI SE REGISTRA O MODIFICA*/
					IF NOT EXISTS(SELECT 4 AS ERRNO 
							FROM ir_product_lang 
								WHERE id_product = ID_P
								AND id_lang  	 = langId) THEN
						BEGIN
							INSERT INTO ir_product_lang(id_product_lang,id_lang,id_product,id_tax_rule,id_type_of_currency,title_product_lang,subtitle_product_lang,general_price_product_lang,text_button_general_price_product_lang,predominant_color_product_lang,background_color_degraded_product_lang,general_stock_product_lang,reference_product_lang,friendly_url_product_lang,general_link_product_lang,text_button_general_link_product_lang,description_small_product_lang,description_large_product_lang,special_specifications_product_lang,clave_prod_serv_sat_product_lang,clave_unidad_sat_product_lang,meta_title_product_lang,meta_description_product_lang,meta_keywords_product_lang)
							VALUES(NULL,langId,ID_P,ID_TA,ID_CU,TI,SUB_TI,PRE,BTN_PRE,COL_PRE,BG_COL,STOK,REF,FRIENDLY,GE_LI,BTN_GE_LI,DE_SM,DE_LA,ESPECI,CL_PR,CL_UN,ME_TI,ME_DESC,ME_KY);

							SELECT 4 AS ERRNO;
						END;
					ELSE
						/*MODIFICACION*/
						BEGIN
							UPDATE ir_product_lang p_l
								INNER JOIN ir_product p
									ON p_l.id_product=p.id_product

							SET 	p.id_type_product 				= ID_T_P,
								p_l.id_tax_rule 				= ID_TA,
								p_l.id_type_of_currency				= ID_CU,
								p_l.title_product_lang 				= TI,
								p_l.subtitle_product_lang 			= SUB_TI,
								p_l.general_price_product_lang 			= PRE,
								p_l.text_button_general_price_product_lang 	= BTN_PRE,
								p_l.predominant_color_product_lang 		= COL_PRE,
								p_l.background_color_degraded_product_lang 	= BG_COL,
								p_l.general_stock_product_lang 			= STOK,
								p_l.reference_product_lang 			= REF,
								p_l.friendly_url_product_lang 			= FRIENDLY,
								p_l.general_link_product_lang 			= GE_LI,
								p_l.text_button_general_link_product_lang 	= BTN_GE_LI,
								p_l.description_small_product_lang 		= DE_SM,
								p_l.description_large_product_lang 		= DE_LA,
								p_l.special_specifications_product_lang 	= ESPECI,
								p_l.clave_prod_serv_sat_product_lang 		= CL_PR,
								p_l.clave_unidad_sat_product_lang 		= CL_UN,
								p_l.meta_title_product_lang 			= ME_TI,
								p_l.meta_description_product_lang 		= ME_DESC,
								p_l.meta_keywords_product_lang 			= ME_KY,
								p_l.last_update_product_lang 			= CURRENT_TIMESTAMP

									WHERE p_l.id_product 			= ID_P
									AND p_l.id_lang 			= langId;

							SELECT 4 AS ERRNO;
						END;
					END IF;
      				    END LOOP;

   				CLOSE cur1;
			ELSE
				/* EL TITULO DEL PRODUCTO YA EXISTE */
				BEGIN
					SELECT 3 AS ERRNO;
				END;
			END IF;
	ELSE
		/* EL ID_P NO EXISTE */
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerInformationSummernote` (IN `ID_IMG` INT, IN `ID_LA` INT, IN `TI` VARCHAR(45))   BEGIN
	DECLARE ID_IMG_LA INT DEFAULT 0;

	/* 1. EL ID LANG NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_lang WHERE id_lang = ID_LA LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. EL ID IMG NO EXISTE */
	ELSEIF NOT EXISTS(SELECT 1 FROM ir_image WHERE id_image = ID_IMG LIMIT 1) THEN
		SELECT 2 AS ERRNO;
		
	/* 3. YA EXISTE REGISTRADA LA INFORMACION DE LA IMAGEN */
	ELSEIF EXISTS(SELECT 1
				  FROM ir_image_lang
				  WHERE id_image = ID_IMG
					AND id_lang = ID_LA
				  LIMIT 1) THEN
		SELECT 3 AS ERRNO;
		
	/* 4. Proceder con la inserción */
	ELSE
		INSERT INTO ir_image_lang(id_image_lang,id_lang,id_image,title_image_lang,s_image_lang_visible)
		VALUES(NULL,ID_LA,ID_IMG,TI,1);
		
		SET ID_IMG_LA = LAST_INSERT_ID();

		SELECT ID_IMG_LA, 4 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerOnlySocialNetworkToUser` (IN `ID_U` INT, IN `ID_SM` INT, IN `URL` VARCHAR(600))   BEGIN
	DECLARE ID_U_SM INT DEFAULT 0;

	/* 1. Verificación (Guard Clause): EL ID USUARIO NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_user WHERE id_user = ID_U) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. Verificación (Guard Clause): EL ID SOCIAL MEDIA NO EXISTE */
	ELSEIF NOT EXISTS(SELECT 1 FROM ir_social_media WHERE id_social_media = ID_SM) THEN
		SELECT 2 AS ERRNO;

	/* 3. Verificación (Guard Clause): YA EXISTE REGISTRADA LA RED SOCIAL */
	ELSEIF EXISTS(SELECT 1 
			FROM ir_user_social_media
				WHERE id_user = ID_U
				AND id_social_media = ID_SM) THEN
		SELECT 3 AS ERRNO;

	/* 4. ÉXITO: Insertar el registro */
	ELSE
		INSERT INTO ir_user_social_media
		VALUES(NULL,ID_SM,ID_U,URL,1,CURRENT_TIMESTAMP);

		/* Se usa LAST_INSERT_ID() como estándar en lugar de @@IDENTITY */
		SET ID_U_SM = LAST_INSERT_ID();
	
		SELECT 4 AS ERRNO,ID_U_SM;
	
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerParentAttribute` (IN `ID_ATTR` INT, IN `PA` INT)   BEGIN
	/* VERIFICAR QUE EXISTA EL ATRIBUTO Y EL PARENT*/
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_attribute 
				WHERE id_attribute = ID_ATTR
				OR parent_id_attribute = PA) THEN

		/*TIENE UN PARENT ID REGISTRADO*/
		IF NOT EXISTS(SELECT 2 AS ERRNO 
				FROM ir_attribute
					WHERE id_attribute = ID_ATTR
					AND parent_id_attribute = 0) THEN

			/*DETERMINAR SI SE ELIMINA O MODIFICA*/
			IF EXISTS(SELECT 2 AS ERRNO 
					FROM ir_attribute 
						WHERE id_attribute = ID_ATTR
						AND parent_id_attribute = PA) THEN

				/*SE DEJA COMO ATRIBUTO PADRE, ES DECIR, PARENT ID 0*/
				BEGIN
					UPDATE ir_attribute
					SET	parent_id_attribute 	= 0
						WHERE id_attribute 	= ID_ATTR;
				END;	
			ELSE
				/*SE CAMBIA POR OTRO PARENT ID*/
				BEGIN
					UPDATE ir_attribute
					SET	parent_id_attribute 	= PA
						WHERE id_attribute 	= ID_ATTR;
				END;
			END IF;
		ELSE
			/*SE REGISTRA POR PRIMERA VEZ EL PARENT ID*/
			BEGIN
				UPDATE ir_attribute
				SET	parent_id_attribute 	= PA
					WHERE id_attribute 	= ID_ATTR;
			END;
		END IF;

		SELECT 2 AS ERRNO;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerParentCategory` (IN `ID_C` INT, IN `PA` INT)   BEGIN
	DECLARE v_current_parent INT;
	DECLARE v_pa_is_parent TINYINT DEFAULT 0;

	SELECT parent_id INTO v_current_parent 
	FROM ir_category 
	WHERE id_category = ID_C;

	/* Comprobar si ID_C existe */
	IF FOUND_ROWS() = 0 THEN
		
		SELECT 1 INTO v_pa_is_parent 
		FROM ir_category 
		WHERE parent_id = PA 
		LIMIT 1;

		IF v_pa_is_parent = 0 THEN
			/* ERRNO 1: ID_C no existe Y PA no es padre de nadie */
			SELECT 1 AS ERRNO;
		ELSE
			UPDATE ir_category SET parent_id = PA WHERE id_category = ID_C;
			SELECT 2 AS ERRNO;
		END IF;
	ELSE
		/* ID_C SÍ existe. v_current_parent tiene el padre actual. */
		
		IF v_current_parent = 0 THEN
			/* SE REGISTRA POR PRIMERA VEZ EL PARENT ID */
			UPDATE ir_category
			SET	parent_id = PA
			WHERE id_category = ID_C;
			
		ELSEIF v_current_parent = PA THEN
			/* SE DEJA COMO CATEGORIA PADRE (Toggle OFF) */
			UPDATE ir_category
			SET	parent_id = 0
			WHERE id_category = ID_C;
				
		ELSE
			/* SE CAMBIA POR OTRO PARENT ID (Re-asignar) */
			UPDATE ir_category
			SET	parent_id = PA
			WHERE id_category = ID_C;
		END IF;

		SELECT 2 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerProduct` (IN `ID_P` INT, IN `ID_U` INT, IN `ID_T_P` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO FROM ir_user WHERE id_user = ID_U) THEN
		/*SI NO EXISTE EL PRODUCTO, SE REGISTRA*/
		IF NOT EXISTS(SELECT 2 AS ERRNO FROM ir_product WHERE id_product = ID_P) THEN
			BEGIN
				INSERT INTO ir_product(id_product,id_user,id_type_product)
				VALUES(ID_P,ID_U,ID_T_P);
			END;	
		END IF;

		SELECT 2 AS ERRNO;
	ELSE
		/*EL ID_U NO EXISTE*/
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerProductAdditionalInformation` (IN `ID_P_LA` INT, IN `ID_T_T` INT, IN `TAG` VARCHAR(100), IN `CONT` TEXT, IN `HIPE` TEXT)   BEGIN
	DECLARE ID_P_LA_ADD_I INT;
	
	/*SI EXISTE EL ID PRODUCTO LANG*/
	IF EXISTS(SELECT 4 AS ERRNO FROM ir_product_lang WHERE id_product_lang = ID_P_LA) THEN

		/*SI EXISTE EL ID TYPE TAG*/
		IF EXISTS(SELECT 4 AS ERRNO FROM ir_type_tag WHERE id_type_tag = ID_T_T) THEN

			/*VALIDAR QUE NO EXISTA REGISTRADO EL TITULO*/
			IF NOT EXISTS(SELECT 4 AS ERRNO 
					FROM ir_product_lang_additional_information
						WHERE id_product_lang = ID_P_LA 
						AND tag_product_lang_additional_information = CONVERT(TAG using utf8mb4) collate utf8mb4_bin) THEN
				BEGIN
					INSERT INTO ir_product_lang_additional_information
					VALUES(NULL,ID_T_T,ID_P_LA,TAG,CONT,HIPE,0,0,1);

					SET ID_P_LA_ADD_I = (SELECT @@IDENTITY);
				
					SELECT ID_P_LA_ADD_I,4 AS ERRNO;
				END;
			ELSE
				/*EL TITULO YA ESTA REGISTRADO*/
				BEGIN
					SELECT 3 AS ERRNO;
				END;
			END IF;
		ELSE
			/*ID ID TYPE TAG NO EXISTE*/
			BEGIN
				SELECT 2 AS ERRNO;
			END;
		END IF;
	ELSE
		/*ID PRODUCTO LANG NO EXISTE*/
		BEGIN
			SELECT 1 AS ERRNO;
		END;	
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerProductCategory` (IN `ID_P` INT, IN `ID_C` INT, IN `P_ID` INT, IN `ID_ACTION` INT)   BEGIN
	DECLARE TOTAL_CATEGORIES INT DEFAULT 0;
	DECLARE EVENTO INT DEFAULT 0;

	/*SI EXISTE EL ID PRODUCTO*/
	IF EXISTS(SELECT 3 AS ERRNO FROM ir_product WHERE id_product = ID_P) THEN
		
		/*ES CATEGORIA PADRE*/
		IF (P_ID = 0) THEN
			/*SI EXISTE LA CATEGORIA*/
			IF EXISTS(SELECT 3 AS ERRNO FROM ir_category WHERE id_category = ID_C) THEN

				/*REGISTRAR*/
				IF (ID_ACTION = 1) THEN
					/*LA CATEGORIA PADRE AUN NO ESTA REGISTRADA*/
					IF NOT EXISTS(SELECT 3 AS ERRNO 
								FROM ir_product_category 
									WHERE id_product 	= ID_P
									AND id_category 	= ID_C) THEN
						BEGIN
							/*REGISTRAR CATEGORIA PADRE*/
							INSERT INTO ir_product_category
							VALUES(NULL,ID_P,ID_C);
							
							SET EVENTO = 1;
						END;
					ELSE
						BEGIN
							SET EVENTO = 2;
						END;
					END IF;
				ELSE
					/*ELIMINAR*/
					IF EXISTS(SELECT 3 AS ERRNO 
							FROM ir_product_category 
								WHERE id_product 	= ID_P
								AND id_category 	= ID_C) THEN
						BEGIN
							DELETE FROM ir_product_category 
								WHERE id_product 	= ID_P
								AND id_category 	= ID_C;

							SET EVENTO = 1;
						END;
					ELSE
						BEGIN
							SET EVENTO = 2;
						END;
					END IF;
				END IF;

				SELECT EVENTO,3 AS ERRNO;
			ELSE
				BEGIN
					SELECT 2 AS ERRNO;
				END;
			END IF;
		ELSE
			/*ES CATEGORIA HIJO*/
			/*SI EXISTE EL PARENT ID*/
			IF EXISTS(SELECT 3 AS ERRNO FROM ir_category WHERE id_category = P_ID) THEN

				/*REGISTRAR*/
				IF (ID_ACTION = 1) THEN
					BEGIN
						/*LA CATEGORIA PADRE AUN NO ESTA REGISTRADA*/
						IF NOT EXISTS(SELECT 3 AS ERRNO 
									FROM ir_product_category 
										WHERE id_product 	= ID_P
										AND id_category 	= P_ID) THEN
							BEGIN
								/*REGISTRAR CATEGORIA PADRE*/
								INSERT INTO ir_product_category
								VALUES(NULL,ID_P,P_ID);
							
								SET EVENTO = 1;
							END;
						ELSE
							BEGIN
								SET EVENTO = 2;
							END;
						END IF;

						/*DESPUES REGISTRAR LA CATEGORIA HIJO*/
						INSERT INTO ir_product_category
						VALUES(NULL,ID_P,ID_C);
					END;	
				ELSE
					/*ELIMINAR*/
					BEGIN
						/*OBTENER EL TOTAL DE CATEGORIAS HIJO REGISTRADAS POR CATEGORIA PADRE, SI SOLO ES UNO SE ELIMINA*/
						SET TOTAL_CATEGORIES = (SELECT count(p_c.id_product)
											FROM ir_product_category p_c
											INNER JOIN ir_category c ON p_c.id_category=c.id_category
												WHERE p_c.id_product = ID_P
												AND c.parent_id = P_ID);
				
						IF (TOTAL_CATEGORIES = 1) THEN
							BEGIN
								DELETE FROM ir_product_category 
									WHERE id_product 	= ID_P
									AND id_category 	= P_ID;

								SET EVENTO = 1;
							END;
						ELSE
							BEGIN
								SET EVENTO = 2;
							END;
						END IF;

						/*DESPUES ELIMINAR LA CATEGORIA HIJO*/
						DELETE FROM ir_product_category 
							WHERE id_product = ID_P
							AND id_category = ID_C;
					END;
				END IF;
		
				SELECT EVENTO,3 AS ERRNO;
			ELSE
				BEGIN
					SELECT 2 AS ERRNO;
				END;
			END IF;
		END IF;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerProductLangPresentation` (IN `ID_T_IMG` INT, IN `ID_P_LA` INT, IN `ID_LA` INT, IN `ISO` VARCHAR(5), IN `ID_ATTR` INT, IN `FO` VARCHAR(15), IN `SI` INT, IN `IMG` VARCHAR(70), IN `PRI` DECIMAL(19,2), IN `STOK` INT, IN `RE` VARCHAR(40), IN `ME_TI` VARCHAR(128), IN `ME_DESC` VARCHAR(255), IN `ME_KY` VARCHAR(500))   BEGIN
	DECLARE ID_IMG INT;
	DECLARE ID_IMG_LA INT;
	DECLARE ID_IMG_LA_VER INT;
	DECLARE S_MAIN_IMG_LA_VER INT;
	DECLARE ID_P_LA_PRE INT;

	/* Manejador de errores para revertir la transacción en caso de fallo */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; /* Error genérico de SQL */
	END;

	/* 1. VALIDACIONES DE ENTRADA (Guard Clauses) */
	/* Se invierte la lógica de anidación para aplanar el código */

	IF NOT EXISTS(SELECT 1 FROM ir_type_image WHERE id_type_image = ID_T_IMG) THEN
		/* NO EXISTE ID TIPO DE IMAGEN */
		SELECT 1 AS ERRNO;
	ELSEIF NOT EXISTS(SELECT 1 FROM ir_product_lang WHERE id_product_lang = ID_P_LA) THEN
		/* NO EXISTE ID PRODUCTO LANG */
		SELECT 2 AS ERRNO;
	ELSEIF NOT EXISTS(SELECT 1 FROM ir_lang WHERE id_lang = ID_LA) THEN
		/* NO EXISTE ID LANG */
		SELECT 3 AS ERRNO;
	ELSEIF EXISTS(SELECT 1
			FROM ir_product_lang_attribute p_l_a
			INNER JOIN ir_product_lang_presentation p_l_pre ON p_l_a.id_product_lang_presentation=p_l_pre.id_product_lang_presentation
			WHERE p_l_pre.id_product_lang = ID_P_LA
			AND p_l_a.id_attribute = ID_ATTR) THEN
		/* EL ID ATRIBUTO YA SE ENCUENTRA ASOCIADO CON EL PRODUCTO */
		SELECT 4 AS ERRNO;
	ELSE
		/* 2. INICIO DE TRANSACCIÓN ATÓMICA */
		START TRANSACTION;

		/* 3. REGISTRAR LA PRESENTACION DEL PRODUCTO */
		INSERT INTO ir_product_lang_presentation
		VALUES(NULL,ID_P_LA,0,0,1);

		SET ID_P_LA_PRE = LAST_INSERT_ID();

		INSERT INTO ir_product_lang_presentation_lang
		VALUES(NULL,ID_P_LA_PRE,PRI,STOK,RE,ME_TI,ME_DESC,ME_KY,CURRENT_TIMESTAMP,1);

		/* 4. ASOCIAR ATRIBUTO AL PRODUCTO */
		INSERT INTO ir_product_lang_attribute
		VALUES(NULL,ID_P_LA_PRE,ID_ATTR);

		/* 5. REGISTRAR IMAGEN */
		INSERT INTO ir_image
		VALUES(NULL,ID_T_IMG,0,0,FO,SI,0,0,1);

		SET ID_IMG = LAST_INSERT_ID();

		INSERT INTO ir_image_lang
		VALUES(NULL,ID_LA,ID_IMG,CONCAT('Presentación del producto',' ',ISO,' ',ID_P_LA_PRE),'','','','','',CONCAT('Producto presentación',' ',ISO),'','','','','',CURRENT_TIMESTAMP,1);
	
		SET ID_IMG_LA = LAST_INSERT_ID();

		/* 6. DETERMINAR TIPO DE IMAGEN: PORTADA O NORMAL */
		/* Se optimiza la lógica para evitar repetir el INSERT */
		IF EXISTS(SELECT 1
				FROM ir_product_lang_presentation p_l_pre
				INNER JOIN ir_product_lang_presentation_image_lang p_l_pre_img_l ON p_l_pre.id_product_lang_presentation=p_l_pre_img_l.id_product_lang_presentation
				WHERE p_l_pre.id_product_lang = ID_P_LA) THEN
			/* NORMAL */
			SET S_MAIN_IMG_LA_VER = 0;
		ELSE
			/* PORTADA */
			SET S_MAIN_IMG_LA_VER = 1;
		END IF;

		/* 7. REGISTRAR VERSIÓN DE IMAGEN */
		INSERT INTO ir_image_lang_version
		VALUES(NULL,ID_IMG_LA,S_MAIN_IMG_LA_VER,1,IMG);

		SET ID_IMG_LA_VER = LAST_INSERT_ID();

		INSERT INTO ir_product_lang_presentation_image_lang
		VALUES(NULL,ID_P_LA_PRE,ID_IMG_LA,0,0);

		/* 8. ÉXITO: CONFIRMAR TRANSACCIÓN */
		COMMIT;
		
		SELECT ID_IMG_LA_VER, S_MAIN_IMG_LA_VER, ID_P_LA_PRE, 8 AS ERRNO;

		/* NOTA: Los códigos de error 5, 6 y 7 del original nunca se ejecutarían
		porque se basaban en una comprobación redundante (IF EXISTS) 
		inmediatamente después de un INSERT. Si el INSERT fallara, 
		el nuevo 'EXIT HANDLER' capturaría el error y haría ROLLBACK.
		*/

	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerProductPromotion` (IN `ID_P_LA` INT, IN `ID_TY_PROM` INT, IN `TI` VARCHAR(70), IN `SK` VARCHAR(30), IN `PRE` DECIMAL(19,2), IN `PORC` INT, IN `DE_SM` TEXT, IN `DE_LA` TEXT, IN `LIN` VARCHAR(600), IN `F_ST` DATE, IN `F_EN` DATE)   BEGIN
	DECLARE ID_P_LA_PROM INT DEFAULT 0;
	
	IF EXISTS(SELECT 3 AS ERRNO FROM ir_product_lang WHERE id_product_lang = ID_P_LA) THEN
		IF NOT EXISTS(SELECT 3 AS ERRNO 
				FROM ir_product_lang_promotion
					WHERE id_product_lang != ID_P_LA 
					AND title_product_lang_promotion = CONVERT(TI using utf8mb4) collate utf8mb4_unicode_ci) THEN
			
			BEGIN
				INSERT INTO ir_product_lang_promotion(id_product_lang_promotion,id_product_lang,id_type_promotion,title_product_lang_promotion,sku_product_lang_promotion,price_discount_product_lang_promotion,discount_rate_product_lang_promotion,description_small_product_lang_promotion,description_large_product_lang_promotion,link_product_lang_promotion,start_date_product_lang_promotion,finish_date_product_lang_promotion)
				VALUES(NULL,ID_P_LA,ID_TY_PROM,TI,SK,PRE,PORC,DE_SM,DE_LA,LIN,F_ST,F_EN);

				SET ID_P_LA_PROM = (SELECT @@IDENTITY);
				
				SELECT ID_P_LA_PROM,3 AS ERRNO;
			END;
		ELSE
			/* YA EXISTE EL TITULO DE LA PROMOCION */
			BEGIN
				SELECT 2 AS ERRNO;
			END;
		END IF;
	ELSE
		/* ID_P_LA NO EXISTE */
		BEGIN
			SELECT 1 AS ERRNO;
		END;	
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerRecord` (IN `ID_U` INT, IN `RE` TEXT)   BEGIN
	/* Verificar si el usuario existe Y tiene un rol.*/
	IF EXISTS(SELECT 1
			FROM ir_role r 
			INNER JOIN ir_user u ON r.id_role=u.id_role
				WHERE u.id_user = ID_U
				LIMIT 1) THEN
		
		/* Usuario válido, insertar registro */
		INSERT INTO ir_record
		VALUE(NULL,ID_U,RE,CURRENT_TIMESTAMP());

		/* Devolver ÉXITO */
		SELECT 2 AS ERRNO;
	ELSE
		/* Usuario no existe o no tiene rol, devolver ERROR */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerSpecificUserFront` (IN `ID_R` INT, IN `NO` VARCHAR(50), IN `L_N` VARCHAR(50), IN `LA_TE` VARCHAR(7), IN `TE` VARCHAR(25), IN `LA_CE` VARCHAR(7), IN `CE` VARCHAR(25), IN `E` VARCHAR(50), IN `U_NA` VARCHAR(20), IN `PA` CHAR(128), IN `SA` CHAR(128))   BEGIN
	DECLARE ID_U INT DEFAULT 0;
	DECLARE U_TIME DATETIME;
	
	/* Manejador de errores para revertir la transacción */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; /* Error genérico de SQL */
	END;
	
	/* Aplanamiento de lógica (Guard Clauses) */

	/* 1. NO EXISTE EL ID_ROLE */
	IF NOT EXISTS(SELECT 1 FROM ir_role WHERE id_role = ID_R LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. YA EXISTE REGISTRADO EL CORREO */
	ELSEIF EXISTS(SELECT 1 FROM ir_user WHERE email_user = CONVERT(E using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1) THEN
		SELECT 2 AS ERRNO;
		
	/* 3. YA EXISTE REGISTRADO EL USERNAME */
	ELSEIF EXISTS(SELECT 1 FROM ir_user WHERE username_website = CONVERT(U_NA using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1) THEN
		SELECT 3 AS ERRNO;

	/* 4. ÉXITO: Todas las validaciones pasaron, proceder con el registro */
	ELSE
		SET U_TIME = CURRENT_TIMESTAMP;

		/* Iniciar transacción para integridad de datos */
		START TRANSACTION;

		INSERT INTO ir_user(id_user,id_role,name_user,last_name_user,gender_user,lada_telephone_user,telephone_user,lada_cell_phone_user,cell_phone_user,email_user,profile_photo_user,username_website,password_user,salt_user,s_user,registration_date_user,last_session_user)
		VALUES(NULL,ID_R,NO,L_N,'U',LA_TE,TE,LA_CE,CE,E,'profile.png',U_NA,PA,SA,0,U_TIME,U_TIME);
					
		SET ID_U = LAST_INSERT_ID(); /* Estandarizado desde @@IDENTITY */

		INSERT INTO ir_user_customize
		VALUES(NULL,1,ID_U,U_TIME);

		/* Confirmar transacción */
		COMMIT;

		SELECT 4 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerSummernote` (IN `ID_T_IMG` INT, IN `FO` VARCHAR(15), IN `SI` INT)   BEGIN
	/* 1. Comprobar si el tipo de imagen existe */
	IF EXISTS(SELECT 1 FROM ir_type_image WHERE id_type_image = ID_T_IMG LIMIT 1) THEN
		
		/* 2. Insertar la imagen */
		INSERT INTO ir_image(id_image,id_type_image,format_image,size_image,s_image)
		VALUES(NULL,ID_T_IMG,FO,SI,1);
			
		/* 3. Devolver el ID recién insertado y el éxito */
		SELECT LAST_INSERT_ID() AS ID_IMG, 2 AS ERRNO;
		
	ELSE
		/* Tipo de imagen no encontrado */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerUser` (IN `ID_R` INT, IN `NO` VARCHAR(50), IN `L_N` VARCHAR(50), IN `RF` VARCHAR(13), IN `CU` VARCHAR(18), IN `MI` VARCHAR(25), IN `ABO` TEXT, IN `BIOGRA` TEXT, IN `BI` DATE, IN `AG` INT, IN `GE` VARCHAR(5), IN `LA_TE` VARCHAR(7), IN `TE` VARCHAR(25), IN `LA_CE` VARCHAR(7), IN `CE` VARCHAR(25), IN `E` VARCHAR(50), IN `SHIP` VARCHAR(200), IN `AD` VARCHAR(70), IN `CO` VARCHAR(30), IN `ST` VARCHAR(25), IN `CI` VARCHAR(30), IN `MUN` VARCHAR(30), IN `COLO` VARCHAR(30), IN `CP` VARCHAR(7), IN `STREET` VARCHAR(30), IN `N_EX` VARCHAR(10), IN `N_IN` VARCHAR(10), IN `STREET1` VARCHAR(30), IN `STREET2` VARCHAR(30), IN `OT_REF` VARCHAR(50), IN `NA` VARCHAR(20), IN `FIL` TEXT, IN `U_NA` VARCHAR(20), IN `PA` CHAR(128), IN `SA` CHAR(128))   BEGIN
	DECLARE ID_U INT DEFAULT 0;
	DECLARE U_TIME DATETIME;

	/* Manejador de errores para revertir la transacción en caso de fallo */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; /* Error genérico de SQL */
	END;

	/* 1. EL ID ROLE NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_role WHERE id_role = ID_R LIMIT 1) THEN
		SELECT 1 AS ERRNO;
	
	/* 2. YA EXISTE REGISTRADO EL CORREO */
	ELSEIF EXISTS(SELECT 1 FROM ir_user WHERE email_user = CONVERT(E using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1) THEN
		SELECT 2 AS ERRNO;
	
	/* 3. YA EXISTE REGISTRADO EL RFC */
	ELSEIF EXISTS(SELECT 1 FROM ir_user WHERE rfc_user = CONVERT(RF using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1) THEN
		SELECT 3 AS ERRNO;
	
	/* 4. YA EXISTE REGISTRADO EL CURP */
	ELSEIF EXISTS(SELECT 1 FROM ir_user WHERE curp_user = CONVERT(CU using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1) THEN
		SELECT 4 AS ERRNO;
	
	/* 5. YA EXISTE REGISTRADO EL ID MIEMBRO */
	ELSEIF (MI IS NOT NULL AND EXISTS(SELECT 1 FROM ir_user WHERE membership_number_user = CONVERT(MI using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1)) THEN
		SELECT 5 AS ERRNO;
	
	/* 6. YA EXISTE REGISTRADO EL USERNAME */
	ELSEIF (U_NA IS NOT NULL AND EXISTS(SELECT 1 FROM ir_user WHERE username_website = CONVERT(U_NA using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1)) THEN
		SELECT 6 AS ERRNO;

	/* 7. ÉXITO: Todas las validaciones pasaron */
	ELSE
		SET U_TIME = CURRENT_TIMESTAMP;

		/* Iniciar transacción para integridad de datos */
		START TRANSACTION;

		/* Bloque INSERT consolidado, se ejecuta una sola vez */
		INSERT INTO ir_user
		VALUES(NULL,ID_R,NO,L_N,RF,CU,MI,ABO,BIOGRA,BI,AG,GE,LA_TE,TE,LA_CE,CE,E,SHIP,AD,CO,ST,CI,MUN,COLO,CP,STREET,N_EX,N_IN,STREET1,STREET2,OT_REF,NA,FIL,'profile.png',U_NA,PA,SA,NULL,0,0,1,U_TIME,U_TIME);
	
		SET ID_U = LAST_INSERT_ID();

		INSERT INTO ir_user_customize
		VALUES(NULL,1,ID_U,U_TIME);

		/* Confirmar transacción */
		COMMIT;

		SELECT 7 AS ERRNO;
	
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerUserWithSocialNetwork` (IN `ID_R` INT, IN `NO` VARCHAR(50), IN `L_N` VARCHAR(50), IN `RF` VARCHAR(13), IN `CU` VARCHAR(18), IN `MI` VARCHAR(25), IN `ABO` TEXT, IN `BIOGRA` TEXT, IN `BI` DATE, IN `AG` INT, IN `GE` VARCHAR(5), IN `LA_TE` VARCHAR(7), IN `TE` VARCHAR(25), IN `LA_CE` VARCHAR(7), IN `CE` VARCHAR(25), IN `E` VARCHAR(50), IN `SHIP` VARCHAR(200), IN `AD` VARCHAR(70), IN `CO` VARCHAR(30), IN `ST` VARCHAR(25), IN `CI` VARCHAR(30), IN `MUN` VARCHAR(30), IN `COLO` VARCHAR(30), IN `CP` VARCHAR(7), IN `STREET` VARCHAR(30), IN `N_EX` VARCHAR(10), IN `N_IN` VARCHAR(10), IN `STREET1` VARCHAR(30), IN `STREET2` VARCHAR(30), IN `OT_REF` VARCHAR(50), IN `NA` VARCHAR(20), IN `FIL` TEXT, IN `U_NA` VARCHAR(20), IN `PA` CHAR(128), IN `SA` CHAR(128), IN `ID_SM` INT, IN `URL` VARCHAR(600))   BEGIN
	DECLARE ID_U INT DEFAULT 0;
	DECLARE U_TIME DATETIME;

	/* Manejador de errores para revertir la transacción en caso de fallo */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; /* Error genérico de SQL */
	END;

	/* 1. EL ID ROLE NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_role WHERE id_role = ID_R LIMIT 1) THEN
		SELECT 1 AS ERRNO;
	
	/* 2. YA EXISTE REGISTRADO EL CORREO */
	ELSEIF EXISTS(SELECT 1 FROM ir_user WHERE email_user = CONVERT(E using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1) THEN
		SELECT 2 AS ERRNO;
	
	/* 3. YA EXISTE REGISTRADO EL RFC */
	ELSEIF EXISTS(SELECT 1 FROM ir_user WHERE rfc_user = CONVERT(RF using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1) THEN
		SELECT 3 AS ERRNO;
	
	/* 4. YA EXISTE REGISTRADO EL CURP */
	ELSEIF EXISTS(SELECT 1 FROM ir_user WHERE curp_user = CONVERT(CU using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1) THEN
		SELECT 4 AS ERRNO;
	
	/* 5. YA EXISTE REGISTRADO EL ID MIEMBRO */
	ELSEIF (MI IS NOT NULL AND EXISTS(SELECT 1 FROM ir_user WHERE membership_number_user = CONVERT(MI using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1)) THEN
		SELECT 5 AS ERRNO;
	
	/* 6. YA EXISTE REGISTRADO EL USERNAME */
	ELSEIF (U_NA IS NOT NULL AND EXISTS(SELECT 1 FROM ir_user WHERE username_website = CONVERT(U_NA using utf8mb4) collate utf8mb4_unicode_ci LIMIT 1)) THEN
		SELECT 6 AS ERRNO;

	/* 7. ÉXITO: Todas las validaciones pasaron */
	ELSE
		SET U_TIME = CURRENT_TIMESTAMP;

		/* Iniciar transacción para integridad de datos */
		START TRANSACTION;

		INSERT INTO ir_user
		VALUES(NULL,ID_R,NO,L_N,RF,CU,MI,ABO,BIOGRA,BI,AG,GE,LA_TE,TE,LA_CE,CE,E,SHIP,AD,CO,ST,CI,MUN,COLO,CP,STREET,N_EX,N_IN,STREET1,STREET2,OT_REF,NA,FIL,'profile.png',U_NA,PA,SA,NULL,0,0,1,U_TIME,U_TIME);
	
		SET ID_U = LAST_INSERT_ID();

		/* Insertar la red social asociada */
		INSERT INTO ir_user_social_media
		VALUES(NULL,ID_SM,ID_U,URL,1,U_TIME);

		/* Insertar la personalización */
		INSERT INTO ir_user_customize
		VALUES(NULL,1,ID_U,U_TIME);

		/* Confirmar transacción */
		COMMIT;

		SELECT 7 AS ERRNO;
	
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showActiveCategoriesByProductId` (IN `ID_P` INT, IN `ID_LA` INT)   BEGIN
	/*CONSULTA BASICA NO COPIAR Y PEGAR*/
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_product_category
				WHERE id_product = ID_P) THEN
		BEGIN
			/*CONSULTA COMPLETA*/
			SELECT c.parent_id,c_l.id_category,c_l.id_category_lang,c_l.title_category_lang, 2 AS ERRNO
				FROM ir_product p
				INNER JOIN ir_product_category p_c ON p_c.id_product=p.id_product
				INNER JOIN ir_category c ON c.id_category=p_c.id_category
				INNER JOIN ir_category_lang c_l ON c_l.id_category=c.id_category
					WHERE p_c.id_product 	= ID_P
					AND c.id_category 	> 4
					AND p.s_product 	= 1
					AND c.s_category 	= 1
					AND c_l.id_lang 	= ID_LA
						GROUP BY c_l.id_category_lang,c_l.title_category_lang
							ORDER BY c_l.id_category;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showActiveLanguage` ()   BEGIN
	IF EXISTS(SELECT 1 FROM ir_lang LIMIT 1) THEN
		
		/* Si la tabla no está vacía, busca los idiomas ACTIVOS (s_lang = 1) */
		SELECT 
			id_lang,
			lang,
			iso_code,
			lang_default,
			2 AS ERRNO
		FROM ir_lang
		WHERE s_lang = 1
		ORDER BY lang_default DESC;
		
	ELSE
		/* Si la tabla 'ir_lang' está completamente vacía, devuelve error 1 */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAllBackgroundsOfTheThemeByCustomizeId` (IN `ID_CU` INT)   BEGIN
	DECLARE TOTAL_BACKGROUNDS INT DEFAULT 0;
	
	/* 1. Obtener el conteo total. Este valor se usa en el SELECT final. */
	SET TOTAL_BACKGROUNDS = (SELECT COUNT(*)
						FROM ir_customize_lang c_l 
						INNER JOIN ir_customize c 
							ON c_l.id_customize=c.id_customize
						INNER JOIN ir_lang l 
							ON l.id_lang=c_l.id_lang
						WHERE l.lang_default = 1
						AND c.id_type_customize = 1);

	/* 2. Comprobar si el conteo es mayor a cero */
	IF (TOTAL_BACKGROUNDS > 0) THEN
	
		/* 3. Devolver los registros Y el conteo total */
		SELECT 
			c_l.id_customize_lang,
			c_l.id_customize,
			c_l.name_customize_lang,
			c_l.background_image_customize_lang,
			TOTAL_BACKGROUNDS,
			2 AS ERRNO
		FROM ir_customize_lang c_l 
		INNER JOIN ir_customize c 
			ON c_l.id_customize=c.id_customize
		INNER JOIN ir_lang l 
			ON l.id_lang=c_l.id_lang
		WHERE l.lang_default = 1
		AND c.id_type_customize = 1
		ORDER BY FIELD(c_l.id_customize, ID_CU) DESC;
			
	ELSE
		/* No se encontraron registros */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAllCategories` ()   BEGIN
	/* Manejador de errores para la transacción de inicialización (seeding) */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; /* Error durante la inicialización */
	END;

	SELECT 
		c.parent_id,
		c_l.id_category,
		c_l.title_category_lang, 
		2 AS ERRNO
	FROM ir_category c 
	INNER JOIN ir_category_lang c_l 
		ON c.id_category=c_l.id_category
	INNER JOIN ir_lang l 
		ON l.id_lang=c_l.id_lang
	WHERE l.lang_default = 1
		AND c_l.id_category != 1
	ORDER BY c_l.id_category;

	/* Comprobar si la consulta anterior devolvió filas */
	IF FOUND_ROWS() = 0 THEN
		IF NOT EXISTS(SELECT 1
				FROM ir_category c 
				INNER JOIN ir_category_lang c_l 
					ON c.id_category=c_l.id_category
				INNER JOIN ir_lang l 
					ON l.id_lang=c_l.id_lang
				WHERE l.lang_default = 1
				LIMIT 1) THEN
			
			/* Se añadió una transacción */
			START TRANSACTION;

			INSERT INTO ir_category
			VALUES(1,1,0,0,'#000000',1),
				  (2,1,0,0,'#000000',1),
				  (3,1,0,0,'#000000',1),
				  (4,1,0,0,'#000000',1);

			INSERT INTO ir_category_lang
			VALUES(NULL,1,1,'Inicio','','','',CURRENT_TIMESTAMP,1),(NULL,2,1,'Home','','','',CURRENT_TIMESTAMP,1),
				  (NULL,1,2,'Categoría','','','',CURRENT_TIMESTAMP,1),(NULL,2,2,'Category','','','',CURRENT_TIMESTAMP,1),
				  (NULL,1,3,'Marcas','','','',CURRENT_TIMESTAMP,1),(NULL,2,3,'Brand','','','',CURRENT_TIMESTAMP,1),
				  (NULL,1,4,'Blog','','','',CURRENT_TIMESTAMP,1),(NULL,2,4,'Blog','','','',CURRENT_TIMESTAMP,1);			
			COMMIT;
		END IF;

		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAllCategoriesByUser` (IN `ID_U` INT)   BEGIN
	/* Manejador de errores para la transacción de inicialización (seeding) */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO; /* Error durante la inicialización */
	END;

	SELECT 
		c.parent_id,
		c_l.id_category,
		c_l.title_category_lang, 
		2 AS ERRNO
	FROM ir_category c 
	INNER JOIN ir_category_lang c_l 
		ON c.id_category=c_l.id_category
	INNER JOIN ir_lang l 
		ON l.id_lang=c_l.id_lang
	WHERE l.lang_default = 1
		AND c_l.id_category != 1
		AND c.id_user = ID_U
	ORDER BY c_l.id_category;

	/* Comprobar si la consulta anterior devolvió filas */
	IF FOUND_ROWS() = 0 THEN
		/* VALIDAR QUE EXISTA CREADA LA CATEGORIA PADRE */
		IF NOT EXISTS(SELECT 1
				FROM ir_category c 
				INNER JOIN ir_category_lang c_l 
					ON c.id_category=c_l.id_category
				INNER JOIN ir_lang l 
					ON l.id_lang=c_l.id_lang
				WHERE l.lang_default = 1
				LIMIT 1) THEN
			
			/* Se añadió una transacción */
			START TRANSACTION;

			INSERT INTO ir_category
			VALUES(1,1,0,0,'#000000',1),
				  (2,1,0,0,'#000000',1),
				  (3,1,0,0,'#000000',1),
				  (4,1,0,0,'#000000',1);

			INSERT INTO ir_category_lang
			VALUES(NULL,1,1,'Inicio','','','',CURRENT_TIMESTAMP,1),(NULL,2,1,'Home','','','',CURRENT_TIMESTAMP,1),
				  (NULL,1,2,'Categoría','','','',CURRENT_TIMESTAMP,1),(NULL,2,2,'Category','','','',CURRENT_TIMESTAMP,1),
				  (NULL,1,3,'Marcas','','','',CURRENT_TIMESTAMP,1),(NULL,2,3,'Brand','','','',CURRENT_TIMESTAMP,1),
				  (NULL,1,4,'Blog','','','',CURRENT_TIMESTAMP,1),(NULL,2,4,'Blog','','','',CURRENT_TIMESTAMP,1);			
			COMMIT;
		END IF;

		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAllCategoryLangImageLang` (IN `ID_C_LA_IMG_LA` INT)   BEGIN
	/* 1. CONSULTA BÁSICA */
	IF EXISTS(SELECT 1
			FROM ir_category_lang_image_lang c_l_img_l
			INNER JOIN ir_image_lang img_l 
				ON img_l.id_image_lang=c_l_img_l.id_image_lang
			INNER JOIN ir_image_lang_version img_ty_ve 
				ON img_ty_ve.id_image_lang=img_l.id_image_lang
			WHERE c_l_img_l.id_category_lang_image_lang = ID_C_LA_IMG_LA
			LIMIT 1) THEN
		
		/* 2. CONSULTA COMPLETA */
		SELECT 
			img_l.id_image,
			img_ty_ve.image_lang,
			l.iso_code,
			2 AS ERRNO
		FROM ir_category_lang_image_lang c_l_img_l
		INNER JOIN ir_image_lang img_l 
			ON img_l.id_image_lang=c_l_img_l.id_image_lang
		INNER JOIN ir_image_lang_version img_ty_ve 
			ON img_ty_ve.id_image_lang=img_l.id_image_lang
		INNER JOIN ir_lang l 
			ON l.id_lang=img_l.id_lang	
		WHERE c_l_img_l.id_category_lang_image_lang = ID_C_LA_IMG_LA
		ORDER BY img_l.id_image;
		
	ELSE
		/* No se encontraron imágenes en la consulta básica */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAllFolders` ()   BEGIN
	SELECT 
		default_route_type_image, 
		2 AS ERRNO
	FROM ir_type_image;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que la tabla está vacía.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAllImagesInTheCategory` (IN `ID_C` INT)   BEGIN
	/* 1. CONSULTA BÁSICA */
	IF EXISTS(SELECT 1
			FROM ir_category_lang c_l 
			INNER JOIN ir_category_lang_image_lang c_l_img_l 
				ON c_l.id_category_lang=c_l_img_l.id_category_lang
			INNER JOIN ir_image_lang img_l 
				ON c_l_img_l.id_image_lang=img_l.id_image_lang	
			INNER JOIN ir_image_lang_version img_ty_ve 
				ON img_ty_ve.id_image_lang=img_l.id_image_lang
			WHERE c_l.id_category = ID_C
			LIMIT 1) THEN
		
		/* 2. CONSULTA COMPLETA */
		SELECT 
			img_l.id_image,
			img_ty_ve.image_lang,
			l.iso_code,
			2 AS ERRNO
		FROM ir_category_lang c_l 
		INNER JOIN ir_category_lang_image_lang c_l_img_l 
			ON c_l.id_category_lang=c_l_img_l.id_category_lang
		INNER JOIN ir_image_lang img_l 
			ON c_l_img_l.id_image_lang=img_l.id_image_lang	
		INNER JOIN ir_image_lang_version img_ty_ve 
			ON img_ty_ve.id_image_lang=img_l.id_image_lang
		INNER JOIN ir_lang l 
			ON l.id_lang=img_l.id_lang	
		WHERE c_l.id_category = ID_C
		ORDER BY img_l.id_image;
		
	ELSE
		/* No se encontraron imágenes en la consulta básica */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAllInactiveUsers` ()   BEGIN
	/* 1. Comprobar si existe CUALQUIER usuario inactivo (lógica básica original) */
	IF EXISTS(SELECT 1
			FROM ir_user
			WHERE s_user = 0
			LIMIT 1) THEN
		
		/* 2. Si existen, buscar y devolver los que tengan rol en idioma default */
		SELECT 
			id_user,
			CONCAT(name_user,' ',last_name_user) AS full_name,
			r_l.name_role, 
			2 AS ERRNO
		FROM ir_user u
		INNER JOIN ir_role_lang r_l 
			ON u.id_role=r_l.id_role
		INNER JOIN ir_lang l 
			ON l.id_lang=r_l.id_lang
		WHERE u.s_user = 0
			AND l.lang_default = 1
		ORDER BY u.id_role ASC,u.last_session_user DESC;
			
	ELSE
		/* 3. Si no hay NINGÚN usuario inactivo en la tabla, devolver error 1 */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAllProductsLangByProductId` (IN `ID_P` INT)   BEGIN
	/*CONSULTA BASICA, NO COPIAR Y PEGAR */
	IF EXISTS(SELECT 2 AS ERRNO FROM ir_product_lang WHERE id_product = ID_P) THEN
		BEGIN
			SELECT p_l.id_product_lang,l.id_lang,l.iso_code,2 AS ERRNO 
				FROM ir_product_lang p_l
				INNER JOIN ir_lang l
					ON p_l.id_lang=l.id_lang					
					WHERE p_l.id_product = ID_P;
		END;
	ELSE
		BEGIN
			/*NO EXISTE EL ID_P*/
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAllVersionsOfTheImageByImageLangId` (IN `ID_IMG_LA` INT, IN `ID_LA` INT)   BEGIN
	SELECT 
		ty_ve_l.id_type_version,
		ty_ve_l.type_version_lang,
		img_l_ve.id_image_lang_version,
		img_l_ve.image_lang,
		img_l.alt_image_lang,
		2 AS ERRNO
	FROM ir_image_lang_version img_l_ve 
	INNER JOIN ir_image_lang img_l 
		ON img_l_ve.id_image_lang=img_l.id_image_lang
	INNER JOIN ir_type_version_lang ty_ve_l 
		ON ty_ve_l.id_type_version=img_l_ve.id_type_version
	WHERE img_l.id_image_lang = ID_IMG_LA
		AND ty_ve_l.id_lang = ID_LA
	ORDER BY ty_ve_l.id_type_version ASC;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAnProducPromotionByProductLangId` (IN `ID_P_LA` INT)   BEGIN
	DECLARE TOTAL_PROMOTIONS INT DEFAULT 0;
	SET lc_time_names = 'es_ES';

	SET TOTAL_PROMOTIONS = (SELECT COUNT(*)
					FROM ir_product_lang_promotion
						WHERE id_product_lang = ID_P_LA
						/*AND DATEDIFF(start_date_product_lang_promotion, NOW()) >= 0*/
						AND DATEDIFF(finish_date_product_lang_promotion, NOW()) >= 0);

	IF (TOTAL_PROMOTIONS > 0) THEN
		BEGIN
			SELECT TOTAL_PROMOTIONS,id_product_lang_promotion,title_product_lang_promotion,sku_product_lang_promotion,price_discount_product_lang_promotion,discount_rate_product_lang_promotion,description_small_product_lang_promotion,description_large_product_lang_promotion,link_product_lang_promotion,start_date_product_lang_promotion,finish_date_product_lang_promotion, 2 AS ERRNO
				FROM ir_product_lang_promotion
					WHERE id_product_lang = ID_P_LA
					/*AND DATEDIFF(start_date_product_lang_promotion, NOW()) >= 0*/
					AND DATEDIFF(finish_date_product_lang_promotion, NOW()) >= 0
						ORDER BY start_date_product_lang_promotion DESC
							LIMIT 0,1;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAThemeByUserId` (IN `ID_U` INT)   BEGIN
	SELECT 
		u_c.id_customize,
		c_l.name_customize_lang,
		c_l.background_image_customize_lang,
		c_l.background_color_customize_lang,
		c_l.color_customize_lang,
		c_l.text_block_1_customize_lang,
		2 AS ERRNO
	FROM ir_user_customize u_c
	INNER JOIN ir_customize_lang c_l 
		ON u_c.id_customize=c_l.id_customize
	INNER JOIN ir_lang l 
		ON l.id_lang=c_l.id_lang
	WHERE u_c.id_user = ID_U
	AND l.lang_default = 1;

	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() es 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAttributeByProductLangPresentationId` (IN `ID_P_LA_PRE` INT, IN `ID_LA` INT)   BEGIN
	/* Ejecutar la consulta principal UNA SOLA VEZ.
	Esta consulta devuelve el conjunto de resultados si se encuentra algo.
	*/
	SELECT 
		a_l.id_attribute,
		a_l.title_attribute_lang,
		a.parent_id_attribute, 
		2 AS ERRNO
	FROM ir_product_lang_attribute AS p_l_a
	INNER JOIN ir_attribute_lang AS a_l 
		ON p_l_a.id_attribute = a_l.id_attribute
	INNER JOIN ir_attribute AS a 
		ON a.id_attribute = a_l.id_attribute
	/* La unión (JOIN) a la tabla 'ir_lang' se eliminó 
	porque no se usaba ningún campo de ella y el filtro 
	ya se aplica en 'a_l.id_lang'.
	*/
	WHERE 
		p_l_a.id_product_lang_presentation = ID_P_LA_PRE
		AND a_l.id_lang = ID_LA;
	
	/*
	Comprobar si la consulta anterior (el SELECT) devolvió alguna fila.
	Si FOUND_ROWS() es 0, significa que no se encontraron resultados.
	*/
	IF FOUND_ROWS() = 0 THEN
		/* No se encontraron filas, devolver el código de error 1. */
		SELECT 1 AS ERRNO;
	END IF;
	/* Si FOUND_ROWS() > 0, los datos ya fueron enviados al cliente 
	por el primer SELECT, y la lógica se completa (preservando el ERRNO 2).
	*/
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAttributes` ()   BEGIN
	/*CONSULTA BÁSICA, NO COPIAR Y PEGAR*/
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_attribute_lang a_l
			INNER JOIN ir_lang l 
				ON l.id_lang=a_l.id_lang
				WHERE l.lang_default 	= 1
				AND a_l.id_attribute 	!= 1) THEN
		BEGIN
			/*CONSULTA COMPLETA, NO COPIAR Y PEGAR*/
			SELECT a.parent_id_attribute,a_l.id_attribute,a_l.title_attribute_lang, 2 AS ERRNO
				FROM ir_attribute a 
				INNER JOIN ir_attribute_lang a_l 
					ON a.id_attribute=a_l.id_attribute
				INNER JOIN ir_lang l 
					ON l.id_lang=a_l.id_lang
					WHERE l.lang_default 	= 1
					AND a_l.id_attribute 	!= 1
						ORDER BY a_l.id_attribute;
		END;
	ELSE
		/*VALIDAR QUE EXISTA CREADO EL ATRIBUTO PADRE*/
		IF NOT EXISTS(SELECT 2 AS ERRNO
				FROM ir_attribute a 
				INNER JOIN ir_attribute_lang a_l 
					ON a.id_attribute=a_l.id_attribute
				INNER JOIN ir_lang l 
					ON l.id_lang=a_l.id_lang
					WHERE l.lang_default = 1) THEN
			BEGIN
				INSERT INTO ir_attribute
                        VALUE(1,1,0,0,1);

				INSERT INTO ir_attribute_lang
                        VALUE(NULL,1,1,'General',CURRENT_TIMESTAMP,1),(NULL,2,1,'General',CURRENT_TIMESTAMP,1);
			END;
		END IF;

		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showAttributesByUser` (IN `ID_U` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_attribute a 
			INNER JOIN ir_attribute_lang a_l 
				ON a.id_attribute=a_l.id_attribute
			INNER JOIN ir_lang l 
				ON l.id_lang=a_l.id_lang
				WHERE l.lang_default 	= 1
				AND a_l.id_attribute 	!= 1
				AND a.id_user 		= ID_U) THEN
		BEGIN
			SELECT a.parent_id_attribute,a_l.id_attribute,a_l.title_attribute_lang, 2 AS ERRNO
				FROM ir_attribute a 
				INNER JOIN ir_attribute_lang a_l 
					ON a.id_attribute=a_l.id_attribute
				INNER JOIN ir_lang l 
					ON l.id_lang=a_l.id_lang
					WHERE l.lang_default 	= 1
					AND a_l.id_attribute 	!= 1
					AND a.id_user 		= ID_U
						ORDER BY a_l.id_attribute;
		END;
	ELSE
		/*VALIDAR QUE EXISTA CREADO EL ATRIBUTO PADRE*/
		IF NOT EXISTS(SELECT 2 AS ERRNO
				FROM ir_attribute a 
				INNER JOIN ir_attribute_lang a_l 
					ON a.id_attribute=a_l.id_attribute
				INNER JOIN ir_lang l 
					ON l.id_lang=a_l.id_lang
					WHERE l.lang_default = 1) THEN
			BEGIN
				INSERT INTO ir_attribute
                        VALUE(1,1,0,0,1);

				INSERT INTO ir_attribute_lang
                        VALUE(NULL,1,1,'General',CURRENT_TIMESTAMP,1),(NULL,2,1,'General',CURRENT_TIMESTAMP,1);
			END;
		END IF;

		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showCategoriesInMediaBoxes` (IN `ID_LA` INT)   BEGIN
	SELECT  count(*) AS TOTAL_CATEGORIES,
		c_l.id_category_lang,
		c_l.title_category_lang,
	        2 AS ERRNO
	FROM ir_product_category p_c
	INNER JOIN ir_category c ON c.id_category=p_c.id_category
	INNER JOIN ir_category_lang c_l ON c_l.id_category=c.id_category
	WHERE c_l.id_lang = ID_LA
		AND c_l.id_category > 4
		AND c.s_category = 1
	GROUP BY c_l.id_category_lang
	ORDER BY c.sort_category,c_l.title_category_lang ASC;

	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showCategoryAttributesByAttributeId` (IN `ID_ATTR` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_attribute_lang a_l 
			INNER JOIN ir_lang l 
				ON l.id_lang=a_l.id_lang
				WHERE a_l.id_attribute 	= ID_ATTR
				AND l.lang_default 	= 1) THEN
		BEGIN
			SELECT a_l.id_attribute_lang,a_l.title_attribute_lang, 2 AS ERRNO
				FROM ir_attribute_lang a_l 
				INNER JOIN ir_lang l 
					ON l.id_lang=a_l.id_lang
					WHERE a_l.id_attribute 	= ID_ATTR
					AND l.lang_default 	= 1
						LIMIT 0,1;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showCategoryAttributesByCategoryId` (IN `ID_C` INT)   BEGIN
	SELECT 
		c_l.id_category_lang,
		c_l.title_category_lang,
		c_l.subtitle_category_lang,
		c_l.description_small_category_lang, 
		2 AS ERRNO
	FROM ir_category_lang c_l 
	INNER JOIN ir_lang l 
		ON l.id_lang=c_l.id_lang
	WHERE c_l.id_category = ID_C
		AND l.lang_default = 1
	LIMIT 0,1;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showCategoryImage` (IN `ID_C_LA` INT, IN `ID_LA` INT)   BEGIN
	IF EXISTS(SELECT 1
			FROM ir_category_lang_image_lang c_l_img_l
			INNER JOIN ir_image_lang img_l 
				ON c_l_img_l.id_image_lang=img_l.id_image_lang	
			WHERE c_l_img_l.id_category_lang = ID_C_LA
			LIMIT 1) THEN
		
		/* 2. CONSULTA COMPLETA */
		SELECT 
			img.format_image,
			img_l.id_image_lang,
			img_l.id_image,
			img_l.title_image_lang,
			img_s_l.name_image_section_lang,
			img_ty_ve.image_lang,
			l.iso_code, 
			2 AS ERRNO
		FROM ir_category_lang_image_lang c_l_img_l 
		INNER JOIN ir_image_lang img_l 
			ON c_l_img_l.id_image_lang=img_l.id_image_lang	
		INNER JOIN ir_image_section_lang img_s_l 
			ON img_s_l.id_image_section_lang=c_l_img_l.id_image_section_lang
		INNER JOIN ir_image img 
			ON img.id_image=img_l.id_image
		INNER JOIN ir_image_lang_version img_ty_ve 
			ON img_ty_ve.id_image_lang=img_l.id_image_lang
		INNER JOIN ir_lang l 
			ON l.id_lang=img_l.id_lang	
		WHERE c_l_img_l.id_category_lang = ID_C_LA
			AND img_l.id_lang = ID_LA
			AND img_s_l.id_lang = ID_LA;
		
	ELSE
		/* No se encontraron imágenes en la consulta básica */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showCategoryInformationInAllLanguages` (IN `ID_C` INT)   BEGIN
	SELECT 
		c_l.id_category_lang AS ID_TABLE_LANG,
		c_l.id_lang AS ID_LANG_TABLE,
		l.id_lang,
		l.iso_code,
		2 AS ERRNO
	FROM ir_category_lang c_l 
	INNER JOIN ir_lang l 
		ON l.id_lang=c_l.id_lang
	WHERE c_l.id_category = ID_C
	ORDER BY c_l.id_lang ASC;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableAdditionalProductInformation` (IN `ID_P_LA` INT)   BEGIN
	DECLARE TOTAL_ADDITIONALS_PRODUCTS INT DEFAULT 0;

	/*CONSULTA BÁSICA, NO COPIAR Y PEGAR*/
	SET TOTAL_ADDITIONALS_PRODUCTS = (SELECT count(id_product_lang_additional_information)
						FROM ir_product_lang_additional_information
							WHERE id_product_lang = ID_P_LA);

	IF (TOTAL_ADDITIONALS_PRODUCTS > 0) THEN
		BEGIN
			SELECT id_product_lang_additional_information,id_type_tag,tag_product_lang_additional_information,content_product_lang_additional_information,s_visible_product_lang_additional_information,hyperlink_product_lang_additional_information,TOTAL_ADDITIONALS_PRODUCTS,2 AS ERRNO
				FROM ir_product_lang_additional_information
					WHERE id_product_lang = ID_P_LA
						ORDER BY sort_product_lang_additional_information,tag_product_lang_additional_information;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableChildCategoryByAttributeId` (IN `ID_ATTR` INT)   BEGIN
	DECLARE TOTAL_ATTRIBUTES INT DEFAULT 0;
					/*CONSULTA BÁSICA, NO COPIAR Y PEGAR*/
	SET TOTAL_ATTRIBUTES = (SELECT count(a_l.id_attribute)
						FROM ir_attribute a
						INNER JOIN ir_attribute_lang a_l 
							ON a.id_attribute=a_l.id_attribute
						INNER JOIN ir_lang l 
							ON l.id_lang=a_l.id_lang
							WHERE a.parent_id_attribute 	= ID_ATTR
            					AND l.lang_default 		= 1);
	IF (TOTAL_ATTRIBUTES > 0) THEN
		BEGIN
			/*CONSULTA COMPLETA, NO COPIAR Y PEGAR*/
			SELECT u.id_user,u.id_role,CONCAT(u.name_user,' ',u.last_name_user) AS full_name,a_l.id_attribute,a_l.id_lang,a_l.id_attribute_lang,a.s_attribute,a_l.title_attribute_lang,a.sort_attribute,a_l.s_attribute_lang_visible,TOTAL_ATTRIBUTES,(SELECT count(id_attribute)
				FROM ir_attribute
					WHERE parent_id_attribute = a_l.id_attribute) AS TOTAL_SUBATTRIBUTES,2 AS ERRNO
				FROM ir_attribute a 
				INNER JOIN ir_user u 
					ON a.id_user=u.id_user
				INNER JOIN ir_attribute_lang a_l 
					ON a.id_attribute=a_l.id_attribute
				INNER JOIN ir_lang l 
					ON l.id_lang=a_l.id_lang	
					WHERE a.parent_id_attribute 	= ID_ATTR
            			AND l.lang_default 		= 1
						ORDER BY u.id_user,a.sort_attribute,a_l.id_attribute,a_l.title_attribute_lang ASC;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableChildCategoryByCategoryId` (IN `ID_C` INT)   BEGIN
	DECLARE TOTAL_CATEGORIES INT DEFAULT 0;
	
	/* 1. OBTENER CONTEO TOTAL (BÁSICO) */
	SET TOTAL_CATEGORIES = (SELECT count(*)
					FROM ir_category c
					INNER JOIN ir_category_lang c_l 
						ON c.id_category=c_l.id_category
					INNER JOIN ir_lang l 
						ON l.id_lang=c_l.id_lang
					WHERE c.parent_id = ID_C
 						AND l.lang_default = 1);
	
	/* 2. Comprobar si el conteo es mayor a cero */
	IF (TOTAL_CATEGORIES > 0) THEN
	
		/* 3. OBTENER LISTA FILTRADA (COMPLETA) */
		SELECT 
			u.id_user,
			u.id_role,
			CONCAT(u.name_user,' ',u.last_name_user) AS full_name,
			c_l.id_category,
			c_l.id_lang,
			c_l.id_category_lang,
			c.s_category,
			c_l.title_category_lang,
			c_l.description_small_category_lang,
			c.sort_category,
			c_l.s_category_lang_visible,
			TOTAL_CATEGORIES,
			(SELECT count(id_category)
				FROM ir_category
				WHERE parent_id = c_l.id_category
			) AS TOTAL_SUBCATEGORIES,
			2 AS ERRNO
		FROM ir_category c 
		INNER JOIN ir_user u 
			ON c.id_user=u.id_user
		INNER JOIN ir_category_lang c_l 
			ON c.id_category=c_l.id_category
		INNER JOIN ir_lang l 
			ON l.id_lang=c_l.id_lang	
		WHERE c.parent_id = ID_C
 			AND l.lang_default = 1
		ORDER BY u.id_user,c.sort_category,c_l.id_category,c_l.title_category_lang ASC;
		
	ELSE
		/* No se encontraron categorías en el conteo básico */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableGalleryUser` (IN `ID_U` INT, IN `ID_T_IMG` INT, IN `LMT` INT)   BEGIN
	DECLARE TOTAL_GALLERY_USER INT DEFAULT 0;
				
	/* 1. OBTENER CONTEO TOTAL (BÁSICO) */
	SET TOTAL_GALLERY_USER = (SELECT COUNT(*)
					FROM ir_image_lang img_l
					INNER JOIN ir_image_lang_version img_l_v 
						ON img_l.id_image_lang=img_l_v.id_image_lang
					INNER JOIN ir_image img 
						ON img.id_image=img_l.id_image
					INNER JOIN ir_user_gallery_image_lang u_g_img_l
						ON u_g_img_l.id_image_lang=img_l.id_image_lang
					INNER JOIN ir_lang l 
						ON l.id_lang=img_l.id_lang
							WHERE img.id_type_image = ID_T_IMG
							AND u_g_img_l.id_user = ID_U
							AND l.lang_default = 1
							AND img_l_v.id_type_version = 1);

	IF (TOTAL_GALLERY_USER > 0) THEN
	
		/* 2. OBTENER LISTA FILTRADA (COMPLETA) */
		SELECT 
			img.id_image,
			img.format_image,
			img.size_image,
			img.s_image,
			img_l.id_image_lang,
			img_l.title_image_lang,
			img_l.last_update_image_lang,
			img_l_v.image_lang,
			l.iso_code,
			TOTAL_GALLERY_USER,
			2 AS ERRNO
		FROM ir_image_lang img_l
		INNER JOIN ir_image_lang_version img_l_v 
			ON img_l.id_image_lang=img_l_v.id_image_lang
		INNER JOIN ir_image img 
			ON img.id_image=img_l.id_image
		INNER JOIN ir_user_gallery_image_lang u_g_img_l
			ON u_g_img_l.id_image_lang=img_l.id_image_lang
		INNER JOIN ir_lang l 
			ON l.id_lang=img_l.id_lang	
		WHERE img.id_type_image = ID_T_IMG
			AND u_g_img_l.id_user = ID_U
			AND l.lang_default = 1
			AND img_l_v.id_type_version = 1
		ORDER BY img.sort_image
		LIMIT 0,LMT;
			
	ELSE
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableParentAttributes` ()   BEGIN
	DECLARE TOTAL_ATTRIBUTES INT DEFAULT 0;
					/*CONSULTA BÁSICA, NO COPIAR Y PEGAR*/
	SET TOTAL_ATTRIBUTES = (SELECT count(a_l.id_attribute)
					FROM ir_attribute a
					INNER JOIN ir_attribute_lang a_l 
						ON a.id_attribute=a_l.id_attribute
					INNER JOIN ir_lang l 
						ON l.id_lang=a_l.id_lang
							WHERE l.lang_default 		= 1
            					AND a.parent_id_attribute 	= 0
							AND a_l.id_attribute 		!= 1);
	
	IF (TOTAL_ATTRIBUTES > 0) THEN
		BEGIN
			/*CONSULTA COMPLETA, NO COPIAR Y PEGAR*/
			SELECT u.id_user,u.id_role,CONCAT(u.name_user,' ',u.last_name_user) AS full_name,a_l.id_attribute,a_l.id_lang,a_l.id_attribute_lang,a.s_attribute,a_l.title_attribute_lang,a.sort_attribute,a_l.s_attribute_lang_visible,TOTAL_ATTRIBUTES,(SELECT count(id_attribute)
				FROM ir_attribute
					WHERE parent_id_attribute = a_l.id_attribute) AS TOTAL_SUBATTRIBUTES,2 AS ERRNO
				FROM ir_attribute a 
				INNER JOIN ir_user u 
					ON a.id_user=u.id_user
				INNER JOIN ir_attribute_lang a_l 
					ON a.id_attribute=a_l.id_attribute
				INNER JOIN ir_lang l 
					ON l.id_lang=a_l.id_lang	
					WHERE l.lang_default 		= 1
					AND a.parent_id_attribute 	= 0
					AND a_l.id_attribute 		!= 1
						ORDER BY u.id_user,a.sort_attribute,a_l.id_attribute,a_l.title_attribute_lang ASC;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableParentAttributesByUser` (IN `ID_U` INT)   BEGIN
	DECLARE TOTAL_ATTRIBUTES INT DEFAULT 0;
					/*CONSULTA BÁSICA, NO COPIAR Y PEGAR*/
	SET TOTAL_ATTRIBUTES = (SELECT count(a_l.id_attribute)
					FROM ir_attribute a
					INNER JOIN ir_attribute_lang a_l 
						ON a.id_attribute=a_l.id_attribute
					INNER JOIN ir_lang l 
						ON l.id_lang=a_l.id_lang
							WHERE l.lang_default 		= 1
            					AND a.parent_id_attribute 	= 0
							AND a_l.id_attribute 		!= 1
							AND a.id_user 			= ID_U);

	IF (TOTAL_ATTRIBUTES > 0) THEN
		BEGIN
			/*CONSULTA COMPLETA, NO COPIAR Y PEGAR*/
			SELECT u.id_user,u.id_role,CONCAT(u.name_user,' ',u.last_name_user) AS full_name,a_l.id_attribute,a_l.id_lang,a_l.id_attribute_lang,a.s_attribute,a_l.title_attribute_lang,a.sort_attribute,a_l.s_attribute_lang_visible,TOTAL_ATTRIBUTES,(SELECT count(id_attribute)
				FROM ir_attribute
					WHERE parent_id_attribute = a_l.id_attribute) AS TOTAL_SUBATTRIBUTES,2 AS ERRNO
				FROM ir_attribute a 
				INNER JOIN ir_user u 
					ON a.id_user=u.id_user
				INNER JOIN ir_attribute_lang a_l 
					ON a.id_attribute=a_l.id_attribute
				INNER JOIN ir_lang l 
					ON l.id_lang=a_l.id_lang	
					WHERE l.lang_default 		= 1
					AND a.parent_id_attribute 	= 0
					AND a_l.id_attribute 		!= 1
					AND a.id_user 			= ID_U
						ORDER BY a.sort_attribute,a_l.id_attribute,a_l.title_attribute_lang ASC;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableParentCategory` ()   BEGIN
	DECLARE TOTAL_CATEGORIES INT DEFAULT 0;
	
	SET TOTAL_CATEGORIES = (SELECT count(*)
					FROM ir_category c
					INNER JOIN ir_category_lang c_l 
						ON c.id_category=c_l.id_category
					INNER JOIN ir_lang l 
						ON l.id_lang=c_l.id_lang
					WHERE l.lang_default = 1
					AND c.parent_id = 0
					AND c_l.id_category != 1);
	
	/* 2. Comprobar si el conteo es mayor a cero */
	IF (TOTAL_CATEGORIES > 0) THEN
	
		/* 3. OBTENER LISTA FILTRADA (COMPLETA) */
		SELECT 
			u.id_user,
			u.id_role,
			CONCAT(u.name_user,' ',u.last_name_user) AS full_name,
			c_l.id_category,
			c_l.id_lang,
			c_l.id_category_lang,
			c.s_category,
			c_l.title_category_lang,
			c_l.description_small_category_lang,
			c.sort_category,
			c_l.s_category_lang_visible,
			TOTAL_CATEGORIES,
			(SELECT count(id_category)
				FROM ir_category
				WHERE parent_id = c_l.id_category
			) AS TOTAL_SUBCATEGORIES,
			2 AS ERRNO
		FROM ir_category c 
		INNER JOIN ir_user u 
			ON c.id_user=u.id_user
		INNER JOIN ir_category_lang c_l 
			ON c.id_category=c_l.id_category
		INNER JOIN ir_lang l 
			ON l.id_lang=c_l.id_lang	
		WHERE l.lang_default = 1
			AND c.parent_id = 0
			AND c_l.id_category != 1
		ORDER BY u.id_user,c.sort_category,c_l.id_category,c_l.title_category_lang ASC;
		
	ELSE
		/* No se encontraron categorías en el conteo básico */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableParentCategoryByUser` (IN `ID_U` INT)   BEGIN
	DECLARE TOTAL_CATEGORIES INT DEFAULT 0;
	
	SET TOTAL_CATEGORIES = (SELECT count(*)
					FROM ir_category c
					INNER JOIN ir_category_lang c_l 
						ON c.id_category=c_l.id_category
					INNER JOIN ir_lang l 
						ON l.id_lang=c_l.id_lang
					WHERE l.lang_default = 1
						AND c.parent_id = 0
						AND c_l.id_category != 1
						AND c.id_user = ID_U);

	/* 2. Comprobar si el conteo es mayor a cero */
	IF (TOTAL_CATEGORIES > 0) THEN
	
		/* 3. OBTENER LISTA FILTRADA (COMPLETA) */
		SELECT 
			u.id_user,
			u.id_role,
			CONCAT(u.name_user,' ',u.last_name_user) AS full_name,
			c_l.id_category,
			c_l.id_lang,
			c_l.id_category_lang,
			c.s_category,
			c_l.title_category_lang,
			c_l.description_small_category_lang,
			c.sort_category,
			c_l.s_category_lang_visible,
			TOTAL_CATEGORIES,
			(SELECT count(id_category)
				FROM ir_category
				WHERE parent_id = c_l.id_category
			) AS TOTAL_SUBCATEGORIES,
			2 AS ERRNO
		FROM ir_category c 
		INNER JOIN ir_user u 
			ON c.id_user=u.id_user
		INNER JOIN ir_category_lang c_l 
			ON c.id_category=c_l.id_category
		INNER JOIN ir_lang l 
			ON l.id_lang=c_l.id_lang	
		WHERE l.lang_default = 1
			AND c.parent_id = 0
			AND c_l.id_category != 1
			AND c.id_user = ID_U
		ORDER BY c.sort_category,c_l.id_category,c_l.title_category_lang ASC;
		
	ELSE
		/* No se encontraron categorías en el conteo básico */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableProduct` ()   BEGIN
	DECLARE TOTAL_PRODUCTS INT DEFAULT 0;
					/*CONSULTA BÁSICA, NO COPIAR Y PEGAR*/
	SET TOTAL_PRODUCTS = (SELECT count(p.id_product)
				FROM ir_product p
				INNER JOIN ir_user u ON p.id_user=u.id_user
				INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
				INNER JOIN ir_lang l ON l.id_lang=p_l.id_lang
					WHERE l.lang_default = 1);
	IF (TOTAL_PRODUCTS > 0) THEN
		BEGIN
			SELECT u.id_user,u.id_role,CONCAT(u.name_user,' ',u.last_name_user) AS full_name,p.id_product,p_l.id_lang,p_l.id_product_lang,p.s_product,p_l.title_product_lang,cu_l.symbol_type_of_currency_lang,p_l.general_price_product_lang,p_l.general_stock_product_lang,p_l.reference_product_lang,p_l.friendly_url_product_lang,p_l.creation_date_product_lang,p_l.last_update_product_lang,p.sort_product,p.s_product_visible,TOTAL_PRODUCTS,2 AS ERRNO
				FROM ir_product p
				INNER JOIN ir_user u ON p.id_user=u.id_user
				INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
				INNER JOIN ir_type_of_currency_lang cu_l ON cu_l.id_type_of_currency=p_l.id_type_of_currency
				INNER JOIN ir_lang l ON l.id_lang=p_l.id_lang	
					WHERE l.lang_default 	= 1
                                        AND  cu_l.id_lang 	= p_l.id_lang
						ORDER BY p.id_user,p.id_type_product,p.sort_product,p_l.title_product_lang ASC;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableProductByUser` (IN `ID_U` INT)   BEGIN
	DECLARE TOTAL_PRODUCTS INT DEFAULT 0;
					/*CONSULTA BÁSICA, NO COPIAR Y PEGAR*/
	SET TOTAL_PRODUCTS = (SELECT count(p.id_product)
				FROM ir_product p
				INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
				INNER JOIN ir_lang l ON l.id_lang=p_l.id_lang
					WHERE l.lang_default 	= 1
					AND p.id_user 		= ID_U);

	IF (TOTAL_PRODUCTS > 0) THEN
		BEGIN
			SELECT p.id_product,p_l.id_lang,p_l.id_product_lang,p.s_product,p_l.title_product_lang,cu_l.symbol_type_of_currency_lang,p_l.general_price_product_lang,p_l.general_stock_product_lang,p_l.reference_product_lang,p_l.friendly_url_product_lang,p_l.creation_date_product_lang,p_l.last_update_product_lang,p.sort_product,p.s_product_visible,TOTAL_PRODUCTS,2 AS ERRNO
				FROM ir_product p
				INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
				INNER JOIN ir_type_of_currency_lang cu_l ON cu_l.id_type_of_currency=p_l.id_type_of_currency
				INNER JOIN ir_lang l ON l.id_lang=p_l.id_lang	
					WHERE l.lang_default 	= 1
					AND p.id_user 		= ID_U
					AND cu_l.id_lang 	= p_l.id_lang
						ORDER BY p.id_type_product,p.sort_product,p_l.title_product_lang ASC;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableProductPromotions` (IN `ID_P_LA` INT)   BEGIN
	DECLARE TOTAL_PRODUCT_PROMOTIONS INT DEFAULT 0;

	/*CONSULTA BÁSICA, NO COPIAR Y PEGAR*/
	SET TOTAL_PRODUCT_PROMOTIONS = (SELECT count(id_product_lang_promotion)
						FROM ir_product_lang_promotion
							WHERE id_product_lang = ID_P_LA);

	IF (TOTAL_PRODUCT_PROMOTIONS > 0) THEN
		BEGIN
			SET lc_time_names = 'es_ES';

			SELECT id_product_lang_promotion,id_type_promotion,title_product_lang_promotion,sku_product_lang_promotion,description_small_product_lang_promotion,price_discount_product_lang_promotion,discount_rate_product_lang_promotion,start_date_product_lang_promotion,date_format(start_date_product_lang_promotion,'%W %d de %M del %Y') AS start_date_product_lang_promotion_format,finish_date_product_lang_promotion,date_format(finish_date_product_lang_promotion,'%W %d de %M del %Y') AS finish_date_product_lang_promotion_format,s_visible_product_lang_promotion,s_product_lang_promotion,TOTAL_PRODUCT_PROMOTIONS,2 AS ERRNO
				FROM ir_product_lang_promotion
					WHERE id_product_lang = ID_P_LA
						ORDER BY start_date_product_lang_promotion ASC;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableSlider` (IN `ID_T_IMG` INT)   BEGIN
	SELECT 
		img.id_image,
		img.format_image,
		img.size_image,
		img.s_image,
		img_l.id_image_lang,
		img_l.title_image_lang,
		img_l.last_update_image_lang,
		img_l_v.image_lang,
		(SELECT m_l.title_menu_lang
			FROM ir_menu_image m_img 
			INNER JOIN ir_menu_lang m_l 
				ON m_l.id_menu=m_img.id_menu
			WHERE m_img.id_image = img.id_image
			LIMIT 0,1
		) AS title_menu_lang,
		l.iso_code,
		COUNT(*) OVER() AS TOTAL_SLIDER,
		2 AS ERRNO
	FROM ir_image_lang img_l
	INNER JOIN ir_image_lang_version img_l_v 
		ON img_l.id_image_lang=img_l_v.id_image_lang
	INNER JOIN ir_image img 
		ON img.id_image=img_l.id_image
	INNER JOIN ir_lang l 
		ON l.id_lang=img_l.id_lang	
	WHERE img.id_type_image = ID_T_IMG
		AND l.lang_default = 1
		AND img_l_v.id_type_version = 1
	ORDER BY img.sort_image;

	/* Comprobar si la consulta anterior devolvió filas */
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDatatableUserDiscardingIdUserAdmin` (IN `ID_U` INT)   BEGIN
	DECLARE TOTAL_USER INT DEFAULT 0;
	
	/* 1. OBTENER CONTEO TOTAL (BÁSICO) */
	SET TOTAL_USER = (SELECT count(*) FROM ir_user WHERE id_user != ID_U);

	IF (TOTAL_USER > 0) THEN
	
		/* 2. OBTENER LISTA FILTRADA (COMPLETA) */
		SELECT 
			u.id_user,
			CONCAT(u.name_user,' ',u.last_name_user) AS full_name,
			u.membership_number_user,
			u.email_user,
			u.profile_photo_user,
			u.username_website,
			u.s_user,
			u.last_session_user,
			r_l.name_role,
			TOTAL_USER, /* Se devuelve el conteo total */
			2 AS ERRNO
		FROM ir_user u 
		INNER JOIN ir_role_lang r_l 
			ON u.id_role=r_l.id_role
		INNER JOIN ir_lang l 
			ON l.id_lang=r_l.id_lang	
		WHERE l.lang_default = 1
		AND u.id_user != ID_U
		ORDER BY u.sort_user ASC;
			
	ELSE
		/* No se encontraron usuarios en el conteo básico */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showDefaultLanguage` ()   BEGIN
	SELECT id_lang,lang,iso_code,2 AS ERRNO
		FROM ir_lang
			WHERE s_lang = 1
			AND lang_default = 1
				LIMIT 0,1;
	
	/* Comprobar si la consulta anterior (el SELECT) devolvió alguna fila.
	Si FOUND_ROWS() es 0, significa que no se encontró el idioma.
	*/
	IF FOUND_ROWS() = 0 THEN
		/* No se encontraron filas, devolver el código de error 1. */
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (incluyendo ERRNO 2) ya fueron 
	enviados al cliente por el primer SELECT, y la ejecución termina.
	*/
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showFolderByCustomizeId` (IN `ID_C` INT)   BEGIN
	SELECT t_c.default_type_route_customize, 2 AS ERRNO
	FROM ir_customize c
	INNER JOIN ir_type_customize t_c 
		ON c.id_type_customize=t_c.id_type_customize
	INNER JOIN ir_customize_lang c_l 
		ON c_l.id_customize=c.id_customize
	INNER JOIN ir_lang l 
		ON l.id_lang=c_l.id_lang
	WHERE c.id_customize = ID_C
	AND l.lang_default = 1
	ORDER BY t_c.sort_type_customize ASC
	LIMIT 0,1;

	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() es 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showFolderByIdTypeImage` (IN `ID_T_IMG` INT)   BEGIN
	SELECT 
		default_route_type_image,
		2 AS ERRNO
	FROM ir_type_image 
	WHERE id_type_image = ID_T_IMG;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showFolderPreviousFile` (IN `ID_T_IMG` INT)   BEGIN
	SELECT 
		default_route_type_image,
		2 AS ERRNO
	FROM ir_type_image 
	WHERE id_type_image = ID_T_IMG;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showGalleryProductsHome` (IN `ID_P` INT, IN `ID_LA` INT)   BEGIN
	DECLARE TOTAL_GALLERY_PRODUCT INT DEFAULT 0;
	
				/*CONSULTA BÁSICA, NO COPIAR Y PEGAR*/
	SET TOTAL_GALLERY_PRODUCT = (SELECT count(p_l_img_l.id_product_lang)
					FROM ir_product_lang_image_lang p_l_img_l
					INNER JOIN ir_product_lang p_l 
						ON p_l_img_l.id_product_lang=p_l.id_product_lang
						WHERE p_l.id_product = ID_P);

	IF (TOTAL_GALLERY_PRODUCT > 0) THEN
		BEGIN
			/*CONSULTA COMPLETA, NO COPIAR NI PEGAR*/
			SELECT p_l_img_l.id_product_lang_image_lang,p_l.id_product_lang,img.id_image,img_l.id_image_lang,img_ty_ve.id_image_lang_version,img.format_image,img.size_image,img.s_image,img_l.title_image_lang,img_l.last_update_image_lang,l.iso_code,img_ty_ve.image_lang,img_ty_ve.s_main_image_lang_version,ty_ve_l.type_version_lang,TOTAL_GALLERY_PRODUCT, 2 AS ERRNO
				FROM ir_product_lang_image_lang p_l_img_l
				INNER JOIN ir_product_lang p_l 
					ON p_l_img_l.id_product_lang=p_l.id_product_lang
				INNER JOIN ir_image_lang img_l 
					ON img_l.id_image_lang=p_l_img_l.id_image_lang	
				INNER JOIN ir_image img 
					ON img.id_image=img_l.id_image
				INNER JOIN ir_lang l 
					ON l.id_lang=img_l.id_lang	
				INNER JOIN ir_type_image ty 
					ON ty.id_type_image=img.id_type_image
				INNER JOIN ir_image_lang_version img_ty_ve 
					ON img_ty_ve.id_image_lang=img_l.id_image_lang
				INNER JOIN ir_type_version ty_ve 
					ON ty_ve.id_type_version=img_ty_ve.id_type_version
				INNER JOIN ir_type_version_lang ty_ve_l 
					ON ty_ve.id_type_version=ty_ve_l.id_type_version
					WHERE p_l.id_product 		= ID_P
					AND img_l.id_lang 		= ID_LA
					AND ty_ve_l.id_lang 		= ID_LA
					AND p_l.id_lang 		= ID_LA
						GROUP BY p_l_img_l.id_product_lang_image_lang,img_ty_ve.id_image_lang_version
							ORDER BY img.sort_image;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showIdImageLangByImageIdAndIdLang` (IN `ID_IMG` INT, IN `ID_LA` INT)   BEGIN
	SELECT 
		id_image_lang, 
		2 AS ERRNO
	FROM ir_image_lang 
	WHERE id_image = ID_IMG
		AND id_lang = ID_LA;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showInformationAttribute` (IN `ID_ATTR` INT, IN `ID_LA` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_attribute a
			INNER JOIN ir_attribute_lang a_l 
				ON a.id_attribute=a_l.id_attribute
				WHERE a_l.id_attribute = ID_ATTR	
				AND a_l.id_lang = ID_LA) THEN
		BEGIN
			SELECT a_l.id_attribute_lang,a_l.title_attribute_lang, 2 AS ERRNO
				FROM ir_attribute a
				INNER JOIN ir_attribute_lang a_l 
					ON a.id_attribute=a_l.id_attribute
					WHERE a_l.id_attribute = ID_ATTR	
					AND a_l.id_lang = ID_LA
						LIMIT 0,1;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showInformationCategory` (IN `ID_C` INT, IN `ID_LA` INT)   BEGIN
	SELECT 
		c_l.id_category_lang,
		c.color_hexadecimal_category,
		c_l.title_category_lang,
		c_l.subtitle_category_lang,
		c_l.description_small_category_lang,
		c_l.description_large_category_lang, 
		2 AS ERRNO
	FROM ir_category c 
	INNER JOIN ir_category_lang c_l 
		ON c.id_category=c_l.id_category
	WHERE c_l.id_category = ID_C	
		AND c_l.id_lang = ID_LA
	LIMIT 0,1;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showInformationCategoryToUploadImage` (IN `ID_C` INT, IN `ID_LA` INT)   BEGIN
	SELECT 
		c_l.id_category_lang AS ID_TABLE_LANG,
		c_l.title_category_lang AS TITLE_TABLE_LANG,
		2 AS ERRNO
	FROM ir_category c 
	INNER JOIN ir_category_lang c_l ON c.id_category=c_l.id_category
	INNER JOIN ir_lang l ON l.id_lang=c_l.id_lang
	WHERE c_l.id_category = ID_C	
		AND c_l.id_lang = ID_LA
	LIMIT 0,1;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showInformationImageActiveByTypeImageIdAndSection` (IN `ID_TY_IMG` INT, IN `ID_M` INT, IN `ID_LA` INT)   BEGIN
	SELECT 
		img_l.id_image_lang,
		img_l.title_image_lang,
		img_l.alt_image_lang,
		img_l.title_hyperlink_image_lang,
		img_l.link_image_lang,
		img.format_image,
		ty_img.default_route_type_image,
		img_l_v.image_lang,
		img_l.background_color_image_lang,
		img_l.description_small_image_lang,
		description_large_image_lang,
		COUNT(*) OVER() AS TOTAL_SLIDER,
		2 AS ERRNO
	FROM ir_menu_image m_img
	INNER JOIN ir_image img 
		ON m_img.id_image=img.id_image
	INNER JOIN ir_type_image ty_img
		ON img.id_type_image=ty_img.id_type_image
	INNER JOIN ir_image_lang img_l 
		ON img.id_image=img_l.id_image
	INNER JOIN ir_image_lang_version img_l_v 
		ON img_l_v.id_image_lang=img_l.id_image_lang
	WHERE img.id_type_image = ID_TY_IMG
		AND img_l.id_lang = ID_LA
		AND m_img.id_menu = ID_M
		AND img_l_v.id_type_version = 1
		AND img.s_image = 1
	ORDER BY img.sort_image ASC;

	/* Comprobar si la consulta anterior devolvió filas */
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showInformationSliderByImageId` (IN `ID_IMG` INT, IN `ID_LA` INT)   BEGIN
	SELECT 
		img.id_type_image,
		img.width_image,
		img.height_image,
		img_l.id_image_lang,
		img_l.title_image_lang,
		img_l.subtitle_image_lang,
		img_l.description_small_image_lang,
		img_l.description_large_image_lang,
		img_l.title_hyperlink_image_lang,
		img_l.link_image_lang,
		img_l.alt_image_lang,
		img_l.background_color_image_lang,
		img_l.background_color_degraded_image_lang,
		img_l.background_repeat_image_lang,
		img_l.background_position_image_lang,
		img_l.background_size_image_lang,
		m_l.id_menu AS id_menu,
		m_l.title_menu_lang AS title_menu_lang,
		2 AS ERRNO
	FROM ir_image img 
	INNER JOIN ir_image_lang img_l 
		ON img.id_image=img_l.id_image
	LEFT JOIN ir_menu_image m_img 
		ON m_img.id_image = img.id_image
	LEFT JOIN ir_menu_lang m_l 
		ON m_l.id_menu=m_img.id_menu
	WHERE img_l.id_image = ID_IMG 
		AND img_l.id_lang = ID_LA
	LIMIT 0,1;

	/* Comprobar si la consulta anterior devolvió filas */
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showMainProductCoverByProductId` (IN `ID_P` INT, IN `ID_LA` INT)   BEGIN
	DECLARE TOTAL_IMAGE INT DEFAULT 0;

			/*CONSULTA BÁSICA, NO COPIAR Y PEGAR*/
	SET TOTAL_IMAGE = (SELECT count(p_l_img_l.id_product_lang)
					FROM ir_product_lang_image_lang p_l_img_l
					INNER JOIN ir_product_lang p_l 
						ON p_l_img_l.id_product_lang=p_l.id_product_lang
						WHERE p_l.id_product = ID_P);

	IF (TOTAL_IMAGE > 0) THEN
		BEGIN
			/*CONSULTA COMPLETA, NO COPIAR NI PEGAR*/
			SELECT p_l_img_l.id_product_lang_image_lang,p_l.id_product_lang,img.id_image,img_l.id_image_lang,img_ty_ve.id_image_lang_version,img.format_image,img.size_image,img.s_image,img_l.title_image_lang,img_l.last_update_image_lang,l.iso_code,img_ty_ve.image_lang,img_ty_ve.s_main_image_lang_version,ty_ve_l.type_version_lang,TOTAL_IMAGE, 2 AS ERRNO
				FROM ir_product_lang_image_lang p_l_img_l
				INNER JOIN ir_product_lang p_l 
					ON p_l_img_l.id_product_lang=p_l.id_product_lang
				INNER JOIN ir_image_lang img_l 
					ON img_l.id_image_lang=p_l_img_l.id_image_lang	
				INNER JOIN ir_image img 
					ON img.id_image=img_l.id_image
				INNER JOIN ir_lang l 
					ON l.id_lang=img_l.id_lang	
				INNER JOIN ir_type_image ty 
					ON ty.id_type_image=img.id_type_image
				INNER JOIN ir_image_lang_version img_ty_ve 
					ON img_ty_ve.id_image_lang=img_l.id_image_lang
				INNER JOIN ir_type_version ty_ve 
					ON ty_ve.id_type_version=img_ty_ve.id_type_version
				INNER JOIN ir_type_version_lang ty_ve_l 
					ON ty_ve.id_type_version=ty_ve_l.id_type_version
					WHERE p_l.id_product 		= ID_P
					AND img_l.id_lang 		= ID_LA
					AND ty_ve_l.id_lang 		= ID_LA
					AND p_l.id_lang 		= ID_LA
					AND img_ty_ve.id_type_version 	= 1
					AND img_ty_ve.s_main_image_lang_version = 1
						ORDER BY img.sort_image	
							LIMIT 0,1;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showMediaGalleryByCategoryId` (IN `ID_C` INT, IN `ID_LA` INT)   BEGIN
	DECLARE TOTAL_IMAGES INT DEFAULT 0;
	
	/* 1. OBTENER CONTEO TOTAL (BÁSICO) */
	SET TOTAL_IMAGES = (SELECT COUNT(*)
					FROM ir_category_lang c_l 
					INNER JOIN ir_category_lang_image_lang c_l_img_l 
						ON c_l.id_category_lang=c_l_img_l.id_category_lang
					INNER JOIN ir_lang l 
						ON l.id_lang=c_l.id_lang	
					WHERE c_l.id_category = ID_C
						AND c_l.id_lang = ID_LA);

	/* 2. Comprobar si el conteo es mayor a cero */
	IF (TOTAL_IMAGES > 0) THEN
	
		/* 3. OBTENER LISTA FILTRADA (COMPLETA) */
		SELECT 
			img.id_image,
			img.format_image,
			img.size_image,
			img.s_image,
			img_l.id_image_lang,
			img_l.title_image_lang,
			img_l.last_update_image_lang,
			l.iso_code,
			img_ty_ve.image_lang,
			img_ty_ve.s_main_image_lang_version,
			img_ty_ve.id_image_lang_version,
			ty_ve_l.type_version_lang,
			img_s_l.name_image_section_lang,
			c_l_img_l.id_category_lang_image_lang,
			TOTAL_IMAGES,
			2 AS ERRNO
		FROM ir_category_lang c_l 
		INNER JOIN ir_category_lang_image_lang c_l_img_l 
			ON c_l.id_category_lang=c_l_img_l.id_category_lang
		INNER JOIN ir_image_lang img_l 
			ON c_l_img_l.id_image_lang=img_l.id_image_lang
		INNER JOIN ir_image_section_lang img_s_l 
			ON c_l_img_l.id_image_section_lang=img_s_l.id_image_section_lang
		INNER JOIN ir_image img 
			ON img.id_image=img_l.id_image
		/* JOIN a 'ty' eliminado */
		INNER JOIN ir_image_lang_version img_ty_ve 
			ON img_ty_ve.id_image_lang=img_l.id_image_lang
		INNER JOIN ir_type_version ty_ve 
			ON ty_ve.id_type_version=img_ty_ve.id_type_version
		INNER JOIN ir_type_version_lang ty_ve_l 
			ON ty_ve.id_type_version=ty_ve_l.id_type_version
		INNER JOIN ir_lang l 
			ON l.id_lang=img_l.id_lang
		WHERE c_l.id_category = ID_C
			AND c_l.id_lang = ID_LA
			AND img_l.id_lang = ID_LA
			AND ty_ve_l.id_lang = ID_LA
			AND img_ty_ve.id_type_version = 1
		GROUP BY img_s_l.name_image_section_lang,img_ty_ve.id_type_version
		ORDER BY img_s_l.name_image_section_lang/*,img_ty_ve.id_type_version*/;
		
	ELSE
		/* No se encontraron imágenes en el conteo básico */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showMediaGalleryByImageId` (IN `ID_IMG` INT, IN `ID_LA` INT)   BEGIN
	SELECT 
		img.id_image,
		img.format_image,
		img.size_image,
		img.s_image,
		img_l.id_image_lang,
		img_l.title_image_lang,
		img_l.last_update_image_lang,
		l.iso_code,
		img_ty_ve.image_lang,
		img_ty_ve.s_main_image_lang_version,
		img_ty_ve.id_image_lang_version,
		ty_ve_l.type_version_lang,
		COUNT(*) OVER() AS TOTAL_IMAGES,
		2 AS ERRNO
	FROM ir_image img 
	INNER JOIN ir_image_lang img_l 
		ON img.id_image=img_l.id_image
	INNER JOIN ir_lang l 
		ON l.id_lang=img_l.id_lang	
	INNER JOIN ir_image_lang_version img_ty_ve 
		ON img_ty_ve.id_image_lang=img_l.id_image_lang
	INNER JOIN ir_type_version_lang ty_ve_l 
		ON ty_ve_l.id_type_version=img_ty_ve.id_type_version
	WHERE img.id_image = ID_IMG
		AND img_l.id_lang = ID_LA
		AND ty_ve_l.id_lang = ID_LA
	ORDER BY img_ty_ve.id_type_version;

	/* Comprobar si la consulta anterior devolvió filas */
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showMenuList` ()   BEGIN
	SELECT 
		m_l.id_menu,
		m_l.title_menu_lang,
		2 AS ERRNO
	FROM ir_menu_lang m_l
	INNER JOIN ir_lang l 
		ON l.id_lang=m_l.id_lang
	WHERE l.lang_default = 1
	ORDER BY m_l.id_menu ASC;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showPersonalInformationUserById` (IN `ID_U` INT)   BEGIN
	SELECT 
		u.*,
		CONCAT(u.name_user,' ',u.last_name_user) AS full_name,
		r_lang.name_role,
		(SELECT count(*)
			FROM ir_user_social_media u_s
			/* El JOIN a 'ir_social_media' era innecesario solo para contar */
			WHERE u_s.id_user = ID_U
		) AS TOTAL_SOCIAL_NETWORK, 
		2 AS ERRNO
	FROM ir_user u
	INNER JOIN ir_role_lang r_lang 
		ON r_lang.id_role=u.id_role
	INNER JOIN ir_lang l 
		ON l.id_lang=r_lang.id_lang
	WHERE 
		u.id_user = ID_U
		AND l.lang_default = 1
	LIMIT 0,1; /* Se mantiene 'LIMIT 0,1' según la lógica original */

	/* Si la consulta principal no devolvió filas 
	(porque el usuario no existe o no cumple los JOINs), 
	se devuelve el código de error 1.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showPreviewImageArrayByImageId` (IN `ID_IMG` INT)   BEGIN
	SELECT 
		img_l_v.image_lang,
		l.iso_code, 
		2 AS ERRNO
	FROM ir_image_lang img_l
	INNER JOIN ir_image_lang_version img_l_v
		ON img_l.id_image_lang=img_l_v.id_image_lang
	INNER JOIN ir_lang l 
		ON l.id_lang=img_l.id_lang
	WHERE img_l.id_image = ID_IMG;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showPreviewImageByImageLangVersionId` (IN `ID_IMG_LA_V` INT)   BEGIN
	SELECT 
		img_l_ve.image_lang,
		l.iso_code, 
		2 AS ERRNO
	FROM ir_image_lang_version img_l_ve
	INNER JOIN ir_image_lang img_l 
		ON img_l_ve.id_image_lang=img_l.id_image_lang
	INNER JOIN ir_lang l 
		ON l.id_lang=img_l.id_lang	
	WHERE img_l_ve.id_image_lang_version = ID_IMG_LA_V;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showPreviewImageVersionArrayByProductId` (IN `ID_P` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_product_lang_presentation_image_lang p_la_pre_img_l
			INNER JOIN ir_product_lang_presentation p_l_pre
				ON p_la_pre_img_l.id_product_lang_presentation=p_l_pre.id_product_lang_presentation
			INNER JOIN ir_product_lang p_l
				ON p_l.id_product_lang=p_l_pre.id_product_lang
			INNER JOIN ir_image_lang img_l
				ON p_la_pre_img_l.id_image_lang=img_l.id_image_lang
			INNER JOIN ir_image_lang_version img_ty_ve 
				ON img_ty_ve.id_image_lang=img_l.id_image_lang
			INNER JOIN ir_lang l 
				ON l.id_lang=img_l.id_lang
					WHERE p_l.id_product = ID_P) THEN
		BEGIN
			SELECT img_ty_ve.image_lang,l.iso_code, 2 AS ERRNO
				FROM ir_product_lang_presentation_image_lang p_la_pre_img_l
				INNER JOIN ir_product_lang_presentation p_l_pre
					ON p_la_pre_img_l.id_product_lang_presentation=p_l_pre.id_product_lang_presentation
				INNER JOIN ir_product_lang p_l
					ON p_l.id_product_lang=p_l_pre.id_product_lang
				INNER JOIN ir_image_lang img_l
					ON p_la_pre_img_l.id_image_lang=img_l.id_image_lang
				INNER JOIN ir_image_lang_version img_ty_ve 
					ON img_ty_ve.id_image_lang=img_l.id_image_lang
				INNER JOIN ir_lang l 
					ON l.id_lang=img_l.id_lang
						WHERE p_l.id_product = ID_P;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showPreviewProductImageArrayByProductId` (IN `ID_P` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_product_lang_image_lang p_l_img_l
			INNER JOIN ir_product_lang p_l 
				ON p_l_img_l.id_product_lang=p_l.id_product_lang
			INNER JOIN ir_image_lang img_l
				ON p_l_img_l.id_image_lang=img_l.id_image_lang
			INNER JOIN ir_image_lang_version img_ty_ve 
				ON img_ty_ve.id_image_lang=img_l.id_image_lang
			INNER JOIN ir_lang l 
				ON l.id_lang=img_l.id_lang
					WHERE p_l.id_product = ID_P) THEN
		BEGIN
			SELECT img_ty_ve.image_lang,l.iso_code, 2 AS ERRNO
				FROM ir_product_lang_image_lang p_l_img_l
				INNER JOIN ir_product_lang p_l 
					ON p_l_img_l.id_product_lang=p_l.id_product_lang
				INNER JOIN ir_image_lang img_l
					ON p_l_img_l.id_image_lang=img_l.id_image_lang
				INNER JOIN ir_image_lang_version img_ty_ve 
					ON img_ty_ve.id_image_lang=img_l.id_image_lang
				INNER JOIN ir_lang l 
					ON l.id_lang=img_l.id_lang
						WHERE p_l.id_product = ID_P;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showPreviewProductLangPresentationImageArrayByProductId` (IN `ID_P` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_product_lang_presentation_image_lang p_l_pre_img_l
			INNER JOIN ir_product_lang_presentation p_l_pre
				ON p_l_pre_img_l.id_product_lang_presentation=p_l_pre.id_product_lang_presentation
			INNER JOIN ir_product_lang p_l
				ON p_l_pre.id_product_lang=p_l.id_product_lang
			INNER JOIN ir_image_lang img_l
				ON p_l_pre_img_l.id_image_lang=img_l.id_image_lang
			INNER JOIN ir_image_lang_version img_ty_ve 
				ON img_ty_ve.id_image_lang=img_l.id_image_lang
			INNER JOIN ir_lang l 
				ON l.id_lang=img_l.id_lang
				WHERE p_l.id_product = ID_P) THEN
		BEGIN
			SELECT img_ty_ve.image_lang,l.iso_code, 2 AS ERRNO
				FROM ir_product_lang_presentation_image_lang p_l_pre_img_l
				INNER JOIN ir_product_lang_presentation p_l_pre
					ON p_l_pre_img_l.id_product_lang_presentation=p_l_pre.id_product_lang_presentation
				INNER JOIN ir_product_lang p_l
					ON p_l_pre.id_product_lang=p_l.id_product_lang
				INNER JOIN ir_image_lang img_l
					ON p_l_pre_img_l.id_image_lang=img_l.id_image_lang
				INNER JOIN ir_image_lang_version img_ty_ve 
					ON img_ty_ve.id_image_lang=img_l.id_image_lang
				INNER JOIN ir_lang l 
					ON l.id_lang=img_l.id_lang
					WHERE p_l.id_product = ID_P;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showProductCategoriesByProductId` (IN `ID_P` INT, IN `ID_LA` INT)   BEGIN
	/*CONSULTA BASICA, NO COPIAR NI PEGAR*/
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_product_category
				WHERE id_product = ID_P) THEN
		BEGIN
			/*CONSULTA COMPLETA, NO COPIAR NI PEGAR*/
			SELECT c_l.id_category,c_l.title_category_lang,c.parent_id,2 AS ERRNO
				FROM ir_category c
				INNER JOIN ir_category_lang c_l
					ON c.id_category=c_l.id_category
				INNER JOIN ir_product_category p_c 
					ON c_l.id_category=p_c.id_category	
						WHERE p_c.id_product 	= ID_P
						AND c_l.id_lang 	= ID_LA
							ORDER BY c_l.id_category;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showProductCategoryByTypeProductId` (IN `ID_T_P` INT, IN `ID_C` INT, IN `ID_LA` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_product p
			INNER JOIN ir_product_lang p_l 
				ON p.id_product=p_l.id_product
			INNER JOIN ir_product_category p_c 
				ON p_c.id_product=p_l.id_product
				WHERE p.id_type_product = ID_T_P
				AND p_c.id_category 	= ID_C
				AND p_l.id_lang 	= ID_LA) THEN
		BEGIN
			SELECT p_c.id_product,p_l.title_product_lang,2 AS ERRNO
				FROM ir_product p
				INNER JOIN ir_product_lang p_l 
					ON p.id_product=p_l.id_product
				INNER JOIN ir_product_category p_c 
					ON p_c.id_product=p_l.id_product
					WHERE p.id_type_product = ID_T_P
					AND p_c.id_category 	= ID_C
					AND p_l.id_lang 	= ID_LA
						/*GROUP BY p_l.title_product_lang*/;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showProductGalleryPresentation` (IN `ID_P_LA` INT, IN `ID_LA` INT)   BEGIN
	DECLARE TOTAL_PRODUCT_GALLERY_PRE INT DEFAULT 0;

	/* 1. Obtener el conteo TOTAL de imágenes para este producto (en todos los idiomas).
	   Este valor se usa tanto para la validación (IF) como para el SELECT final.
	*/
	SET TOTAL_PRODUCT_GALLERY_PRE = (
		SELECT count(*)
		FROM ir_product_lang_presentation AS p_l_pre
		INNER JOIN ir_product_lang_presentation_image_lang AS p_l_pre_img_l 
			ON p_l_pre.id_product_lang_presentation = p_l_pre_img_l.id_product_lang_presentation
		WHERE p_l_pre.id_product_lang = ID_P_LA
	);

	/* 2. Comprobar si existe alguna imagen. Si no, devolver error. */
	IF (TOTAL_PRODUCT_GALLERY_PRE > 0) THEN
	
		/* 3. Si hay imágenes, ejecutar la consulta principal para el idioma específico. */
		SELECT 
			img.id_image,
			img.format_image,
			img.size_image,
			img.s_image,
			img_l.id_image_lang,
			img_l.title_image_lang,
			img_l.last_update_image_lang,
			l.iso_code,
			img_ty_ve.image_lang,
			img_ty_ve.s_main_image_lang_version,
			img_ty_ve.id_image_lang_version,
			ty_ve_l.type_version_lang,
			p_l_pre_la.id_product_lang_presentation_lang,
			p_l_pre_la.general_price_product_lang_presentation_lang,
			p_l_pre_la.general_stock_product_lang_presentation_lang,
			p_l_pre_la.reference_product_lang_presentation_lang,
			p_l_pre_la.meta_title_product_lang_presentation_lang,
			p_l_pre_la.meta_description_product_lang_presentation_lang,
			p_l_pre_la.meta_keywords_product_lang_presentation_lang,
			p_l_pre_img_l.id_product_lang_presentation,
			p_l_pre_img_l.s_thumbnail_product_lang_presentation_image_lang,
			p_l_pre_img_l.s_main_product_lang_presentation_image_lang,
			p_l_pre_img_l.id_product_lang_presentation_image_lang,
			TOTAL_PRODUCT_GALLERY_PRE, /* Variable calculada en el paso 1 */
			2 AS ERRNO
		FROM ir_product_lang_presentation AS p_l_pre
		INNER JOIN ir_product_lang_presentation_image_lang AS p_l_pre_img_l 
			ON p_l_pre.id_product_lang_presentation = p_l_pre_img_l.id_product_lang_presentation
		INNER JOIN ir_product_lang_presentation_lang AS p_l_pre_la 
			ON p_l_pre_la.id_product_lang_presentation = p_l_pre.id_product_lang_presentation	
		INNER JOIN ir_image_lang AS img_l 
			ON p_l_pre_img_l.id_image_lang = img_l.id_image_lang	
		INNER JOIN ir_image AS img 
			ON img.id_image = img_l.id_image
		INNER JOIN ir_lang AS l 
			ON l.id_lang = img_l.id_lang
		/* JOIN ELIMINADO: 'ir_type_image ty' no se usaba en el SELECT ni en el WHERE. */
		INNER JOIN ir_image_lang_version AS img_ty_ve 
			ON img_ty_ve.id_image_lang = img_l.id_image_lang
		INNER JOIN ir_type_version AS ty_ve 
			ON ty_ve.id_type_version = img_ty_ve.id_type_version
		INNER JOIN ir_type_version_lang AS ty_ve_l 
			ON ty_ve.id_type_version = ty_ve_l.id_type_version
		WHERE 
			p_l_pre.id_product_lang = ID_P_LA
			AND img_l.id_lang = ID_LA
			AND ty_ve_l.id_lang = ID_LA
			AND img_ty_ve.id_type_version = 1;
			
	ELSE
		/* No se encontraron imágenes en el conteo inicial */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showProductImage` (IN `ID_P_LA` INT)   BEGIN
	/*CONSULTA BASICA, NO COPIAR NI PEGAR*/
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_product_lang_image_lang 					
				WHERE id_product_lang = ID_P_LA) THEN
		BEGIN
			/*CONSULTA COMPLETA, NO COPIAR NI PEGAR*/
			SELECT l.iso_code,img_l.id_image_lang,img_l.id_image,img.format_image,img_l.title_image_lang,img_ty_ve.id_type_version,img_ty_ve.image_lang,2 AS ERRNO
				FROM ir_product_lang_image_lang p_l_img_l 
				INNER JOIN ir_image_lang img_l 
					ON p_l_img_l.id_image_lang=img_l.id_image_lang	
				INNER JOIN ir_image img 
					ON img.id_image=img_l.id_image
				INNER JOIN ir_image_lang_version img_ty_ve 
					ON img_ty_ve.id_image_lang=img_l.id_image_lang
                		INNER JOIN ir_lang l 
					ON l.id_lang=img_l.id_lang
						WHERE p_l_img_l.id_product_lang 	= ID_P_LA
						AND img_ty_ve.id_type_version 		= 1
							ORDER BY img.sort_image
								LIMIT 0,1;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showProductInformationByProductId` (IN `ID_P` INT, IN `ID_LA` INT)   BEGIN
	/*CONSULTA BÁSICA, NO COPIAR Y PEGAR*/
	IF EXISTS(SELECT 1 AS ACTION 
			FROM ir_product_lang p_l
			INNER JOIN ir_type_of_currency_lang cu_l ON cu_l.id_type_of_currency=p_l.id_type_of_currency
				WHERE p_l.id_product 	= ID_P
				AND p_l.id_lang 	= ID_LA
				AND cu_l.id_lang 	= ID_LA) THEN
		BEGIN
			/*CONSULTA COMPLETA, NO COPIAR Y PEGAR*/
			SELECT p.id_user,p.id_type_product,p.s_product,p_l.id_product_lang,p_l.id_tax_rule,cu_l.symbol_type_of_currency_lang,p_l.id_type_of_currency,p_l.title_product_lang,p_l.subtitle_product_lang,p_l.general_price_product_lang,p_l.text_button_general_price_product_lang,p_l.predominant_color_product_lang,p_l.background_color_degraded_product_lang,p_l.general_stock_product_lang,p_l.reference_product_lang,p_l.friendly_url_product_lang,p_l.general_link_product_lang,p_l.text_button_general_link_product_lang,p_l.description_small_product_lang,p_l.description_large_product_lang,p_l.special_specifications_product_lang,p_l.clave_prod_serv_sat_product_lang,p_l.clave_unidad_sat_product_lang,p_l.input_product_lang,p_l.output_product_lang,p_l.meta_title_product_lang,p_l.meta_description_product_lang,p_l.meta_keywords_product_lang,1 AS ACTION 
				FROM ir_product p
				INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
				INNER JOIN ir_type_of_currency_lang cu_l ON cu_l.id_type_of_currency=p_l.id_type_of_currency
					WHERE p_l.id_product 	= ID_P
					AND p_l.id_lang 	= ID_LA
					AND cu_l.id_lang 	= ID_LA;
		END;
	ELSE
		BEGIN
			/*REGISTRO NUEVO*/
			SELECT 2 AS ACTION;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showProductsInMediaBoxes` (IN `ID_LA` INT)   BEGIN
	DECLARE TOTAL_PRODUCTS_MB INT DEFAULT 0;

	SET TOTAL_PRODUCTS_MB = (SELECT COUNT(*)
					FROM ir_product p
					INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
					WHERE p_l.id_lang = ID_LA
				  	AND p.s_product = 1);

	/*CONSULTA BASICA NO COPIAR Y PEGAR*/
	IF TOTAL_PRODUCTS_MB > 0 THEN
		BEGIN
			/*CONSULTA COMPLETA*/
			SELECT p_l.id_product,p_l.id_product_lang,p_l.title_product_lang,p_l.subtitle_product_lang,p_l.general_price_product_lang,p_l.predominant_color_product_lang,p_l.reference_product_lang,p_l.description_small_product_lang,p_l.description_large_product_lang,p_l.special_specifications_product_lang,TOTAL_PRODUCTS_MB, 2 AS ERRNO
				FROM ir_product p
				INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
				WHERE p_l.id_lang = ID_LA
				  AND p.s_product = 1
				ORDER BY p.sort_product,p_l.title_product_lang ASC;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showProductsWithLimit` (IN `LI` INT)   BEGIN
	DECLARE TOTAL_PRODUCTS INT DEFAULT 0;
					/*CONSULTA BÁSICA, NO COPIAR Y PEGAR*/
	SET TOTAL_PRODUCTS = (SELECT count(p.id_product)
				FROM ir_product p
				INNER JOIN ir_user u ON p.id_user=u.id_user
				INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
				INNER JOIN ir_lang l ON l.id_lang=p_l.id_lang
					WHERE l.lang_default = 1);
	IF (TOTAL_PRODUCTS > 0) THEN
		BEGIN
			SELECT u.id_user,u.id_role,CONCAT(u.name_user,' ',u.last_name_user) AS full_name,p.id_product,p_l.id_lang,p_l.id_product_lang,p.s_product,p_l.title_product_lang,cu_l.symbol_type_of_currency_lang,p_l.general_price_product_lang,p_l.general_stock_product_lang,p_l.reference_product_lang,p_l.friendly_url_product_lang,p_l.creation_date_product_lang,p_l.last_update_product_lang,p.sort_product,p.s_product_visible,TOTAL_PRODUCTS,2 AS ERRNO
				FROM ir_product p
				INNER JOIN ir_user u ON p.id_user=u.id_user
				INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
				INNER JOIN ir_type_of_currency_lang cu_l ON cu_l.id_type_of_currency=p_l.id_type_of_currency
				INNER JOIN ir_lang l ON l.id_lang=p_l.id_lang	
					WHERE l.lang_default 	= 1
                                        AND  cu_l.id_lang 	= p_l.id_lang
						ORDER BY p_l.last_update_product_lang DESC
							LIMIT 0,LI;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showProductType` (IN `ID_LA` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_type_product_lang
				WHERE id_lang = ID_LA) THEN
		BEGIN
			SELECT id_type_product,title_type_product_lang, 2 AS ERRNO
				FROM ir_type_product_lang
					WHERE id_lang = ID_LA
						ORDER BY id_type_product;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showProductTypeByProductId` (IN `ID_P` INT, IN `ID_LA` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_type_product_lang t_p_l
			INNER JOIN ir_product p 
				ON t_p_l.id_type_product=p.id_type_product
				WHERE t_p_l.id_lang 	= ID_LA
				AND p.id_product 	= ID_P) THEN
		BEGIN
			SELECT t_p_l.id_type_product,t_p_l.title_type_product_lang,t_p_l.badge_type_product_lang, 2 AS ERRNO
				FROM ir_type_product_lang t_p_l
				INNER JOIN ir_product p 
					ON t_p_l.id_type_product=p.id_type_product
					WHERE t_p_l.id_lang 	= ID_LA
					AND p.id_product 	= ID_P;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showPromotionTypeList` (IN `ID_LA` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO FROM ir_type_promotion_lang	WHERE id_lang = ID_LA) THEN
		BEGIN
			SELECT id_type_promotion_lang,id_type_promotion,id_type_promotion,type_promotion_lang, 2 AS ERRNO
				FROM ir_type_promotion_lang					
					WHERE id_lang = ID_LA
						ORDER BY id_type_promotion;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showRoleList` ()   BEGIN
	SELECT 
		r_l.id_role,
		r_l.name_role,
		2 AS ERRNO
	FROM ir_role_lang r_l 	
	INNER JOIN ir_lang l 
		ON r_l.id_lang=l.id_lang
	WHERE l.lang_default = 1
	ORDER BY r_l.id_role ASC;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() es 0, significa que no se encontraron roles.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;

	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showSectionListImage` ()   BEGIN
	SELECT 
		img_s_l.id_image_section,
		img_s_l.name_image_section_lang,
		2 AS ERRNO
	FROM ir_image_section_lang img_s_l
	INNER JOIN ir_lang l 
		ON l.id_lang=img_s_l.id_lang
	WHERE l.lang_default = 1
	ORDER BY img_s_l.id_image_section ASC;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showSelectedProductCategories` (IN `ID_P` INT, IN `ID_C` INT)   BEGIN
	IF EXISTS(SELECT 2 AS CHECKED
			FROM ir_product_category
				WHERE id_product = ID_P	
				AND id_category = ID_C) THEN
		BEGIN
			SELECT 2 AS CHECKED;
		END;
	ELSE
		BEGIN
			SELECT 1 AS CHECKED;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showSocialNetworkBySocialMediaId` (IN `ID_SM` INT)   BEGIN
	SELECT 
		name_social_media,
		icon_social_media, 
		2 AS ERRNO
	FROM ir_social_media
	WHERE id_social_media = ID_SM;

	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() es 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showSocialNetworkByUserId` (IN `ID_U` INT)   BEGIN
	IF EXISTS(SELECT 1
			FROM ir_user_social_media
				WHERE id_user = ID_U
				LIMIT 1) THEN
		
		/* CONSULTA COMPLETA */
		SELECT 
			u_s_m.id_user_social_media,
			u_s_m.id_social_media,
			s_m.name_social_media,
			s_m.icon_social_media,
			u_s_m.url_user_social_media, 
			2 AS ERRNO
		FROM ir_user_social_media u_s_m
		INNER JOIN ir_social_media s_m 
			ON s_m.id_social_media=u_s_m.id_social_media
		WHERE u_s_m.id_user = ID_U;
			
	ELSE
		/* No se encontraron redes en la consulta básica */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showSocialNetworkList` ()   BEGIN
	DECLARE TOTAL_SOCIAL_NETWORK INT DEFAULT 0;
	
	/* 1. Obtener el conteo total. Este valor se usa en el SELECT final. */
	SET TOTAL_SOCIAL_NETWORK = (SELECT count(*) FROM ir_social_media);

	/* 2. Comprobar si el conteo es mayor a cero */
	IF (TOTAL_SOCIAL_NETWORK > 0) THEN
	
		/* 3. Devolver los registros Y el conteo total */
		SELECT 
			id_social_media,
			name_social_media,
			TOTAL_SOCIAL_NETWORK,
			2 AS ERRNO
		FROM ir_social_media
		ORDER BY sort_social_media, id_social_media ASC;
			
	ELSE
		/* No se encontraron registros */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showSpecificInformationByProductLangId` (IN `ID_P_LA` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_product_lang
				WHERE id_product_lang = ID_P_LA) THEN
		BEGIN
			SELECT title_product_lang,subtitle_product_lang,general_price_product_lang,text_button_general_price_product_lang,predominant_color_product_lang,background_color_degraded_product_lang,general_stock_product_lang,reference_product_lang,friendly_url_product_lang,general_link_product_lang,text_button_general_link_product_lang,description_small_product_lang,description_large_product_lang,special_specifications_product_lang,clave_prod_serv_sat_product_lang,clave_unidad_sat_product_lang,input_product_lang,output_product_lang,meta_title_product_lang,meta_description_product_lang,meta_keywords_product_lang,2 AS ERRNO
				FROM ir_product_lang
					WHERE id_product_lang = ID_P_LA;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showSubAttributesByParentIdAttribute` (IN `ID_ATTR` INT)   BEGIN
	IF EXISTS(SELECT 2 AS CHECKED
			FROM ir_attribute a
			INNER JOIN ir_attribute_lang a_l 
				ON a.id_attribute=a_l.id_attribute
			INNER JOIN ir_lang l 
				ON l.id_lang=a_l.id_lang
				WHERE a.parent_id_attribute 	= ID_ATTR	
				AND l.lang_default 		= 1) THEN
		BEGIN
			SELECT a_l.id_attribute AS SUBATTRIBUTE, 2 AS CHECKED
				FROM ir_attribute a
				INNER JOIN ir_attribute_lang a_l 
					ON a.id_attribute=a_l.id_attribute
				INNER JOIN ir_lang l 
					ON l.id_lang=a_l.id_lang
					WHERE a.parent_id_attribute 	= ID_ATTR	
					AND l.lang_default 		= 1
						ORDER BY a_l.id_attribute;
		END;
	ELSE
		BEGIN
			SELECT 1 AS CHECKED;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showSubcategoriesByParentId` (IN `ID_C` INT)   BEGIN
	SELECT 
		c_l.id_category AS SUBCATEGORY, 
		2 AS CHECKED
	FROM ir_category c 
	INNER JOIN ir_category_lang c_l 
		ON c.id_category=c_l.id_category
	INNER JOIN ir_lang l 
		ON l.id_lang=c_l.id_lang
	WHERE c.parent_id = ID_C	
		AND l.lang_default = 1
	ORDER BY c_l.id_category;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS CHECKED;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con CHECKED = 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showtaxRuleLangList` ()   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_tax_rule_lang t_l
			INNER JOIN ir_lang l ON l.id_lang=t_l.id_lang
				WHERE l.lang_default = 1) THEN
		BEGIN
			SELECT t_l.id_tax_rule,t_l.title_tax_rule_lang, 2 AS ERRNO
				FROM ir_tax_rule_lang t_l
				INNER JOIN ir_lang l ON l.id_lang=t_l.id_lang
					WHERE l.lang_default = 1
						ORDER BY t_l.id_tax_rule;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showtypeOfCurrencyList` ()   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_type_of_currency_lang t_l
			INNER JOIN ir_lang l ON l.id_lang=t_l.id_lang
				WHERE l.lang_default = 1) THEN
		BEGIN
			SELECT t_l.id_type_of_currency,t_l.type_of_currency_lang, 2 AS ERRNO
				FROM ir_type_of_currency_lang t_l
				INNER JOIN ir_lang l ON l.id_lang=t_l.id_lang
					WHERE l.lang_default = 1
						ORDER BY t_l.id_type_of_currency;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showTypeOfLinkToRemoveCategory` (IN `ID_C_LA` INT, IN `ID_LA` INT)   BEGIN
	SELECT 
		img_l.id_image,
		img_l.id_image_lang, 
		2 AS ERRNO
	FROM ir_category_lang_image_lang c_l_img_l 
	INNER JOIN ir_image_lang img_l 
		ON c_l_img_l.id_image_lang=img_l.id_image_lang	
	WHERE c_l_img_l.id_category_lang = ID_C_LA
		AND img_l.id_lang = ID_LA
	LIMIT 0,1;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		/*INFORMACIÓN BÁSICA*/
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showTypeOfLinkToRemoveProduct` (IN `ID_P_LA` INT)   BEGIN
	DECLARE TOTAL_COVER_IMAGE INT DEFAULT 0;
	DECLARE TOTAL_PRESENTATION INT DEFAULT 0;
	
				
	SET TOTAL_COVER_IMAGE 	= (SELECT COUNT(id_product_lang_image_lang) FROM ir_product_lang_image_lang WHERE id_product_lang = ID_P_LA);
	SET TOTAL_PRESENTATION 	= (SELECT COUNT(id_product_lang_presentation) FROM ir_product_lang_presentation WHERE id_product_lang = ID_P_LA);
	
	/*TIENE PORTADA REGISTRADA*/
	IF (TOTAL_COVER_IMAGE > 0) THEN
		BEGIN
			SELECT 2 AS ERRNO;
		END;
	ELSE
		/*TIENE PRESENTACION*/
		IF (TOTAL_PRESENTATION > 0) THEN
			BEGIN
				SELECT 2 AS ERRNO;
			END;
		ELSE
			/*SOLO TIENE EL REGISTRO BASICO*/
			BEGIN
				SELECT 1 AS ERRNO;
			END;
		END IF;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showTypeTagByTypeTagId` (IN `ID_T_T` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_type_tag_lang t_t
			INNER JOIN ir_lang l ON l.id_lang=t_t.id_lang
				WHERE l.lang_default = 1
				AND t_t.id_type_tag = ID_T_T) THEN
		BEGIN
			SELECT t_t.title_type_tag_lang,t_t.badge_type_tag_lang, 2 AS ERRNO
				FROM ir_type_tag_lang t_t
				INNER JOIN ir_lang l ON l.id_lang=t_t.id_lang
					WHERE l.lang_default = 1
					AND t_t.id_type_tag = ID_T_T;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showTypeTagList` ()   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_type_tag_lang t_t
			INNER JOIN ir_lang l ON l.id_lang=t_t.id_lang
				WHERE l.lang_default = 1) THEN
		BEGIN
			SELECT t_t.id_type_tag,t_t.title_type_tag_lang,2 AS ERRNO
				FROM ir_type_tag_lang t_t
				INNER JOIN ir_lang l ON l.id_lang=t_t.id_lang
					WHERE l.lang_default = 1;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showUserRecord` (IN `ID_U` INT)   BEGIN
	DECLARE TOTAL_USER_HISTORY INT DEFAULT 0;
	
	/* 1. Obtener el conteo total. Este valor se usa en el SELECT final. */
	SET TOTAL_USER_HISTORY = (SELECT count(*) 
							  FROM ir_record 
							  WHERE id_user = ID_U);

	/* 2. Comprobar si el conteo es mayor a cero */
	IF (TOTAL_USER_HISTORY > 0) THEN
	
		/* 3. Devolver los registros y el conteo total */
		SELECT 
			resumen_record,
			date_record,
			TOTAL_USER_HISTORY, 
			2 AS ERRNO
		FROM ir_record
		WHERE id_user = ID_U
		ORDER BY date_record DESC;
			
	ELSE
		/* No se encontraron registros */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showUserRecordWithLimit` (IN `ID_U` INT, IN `LI` INT)   BEGIN
	DECLARE TOTAL_USER_HISTORY INT DEFAULT 0;
	
	/* 1. Obtener el conteo total. Este valor se usa en el SELECT final. */
	SET TOTAL_USER_HISTORY = (SELECT count(*) 
							  FROM ir_record 
							  WHERE id_user = ID_U);

	/* 2. Comprobar si el conteo es mayor a cero */
	IF (TOTAL_USER_HISTORY > 0) THEN
	
		/* 3. Devolver los registros (limitados) y el conteo total */
		SELECT 
			resumen_record,
			date_record,
			TOTAL_USER_HISTORY, 
			2 AS ERRNO
		FROM ir_record
		WHERE id_user = ID_U
		ORDER BY date_record DESC
		LIMIT 0,LI; /* Se mantiene la lógica de LIMIT original */
			
	ELSE
		/* No se encontraron registros */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `showVersionList` ()   BEGIN
	SELECT 
		ty_ve_l.id_type_version,
		ty_ve_l.type_version_lang,
		2 AS ERRNO
	FROM ir_type_version_lang ty_ve_l 
	INNER JOIN ir_lang l 
		ON ty_ve_l.id_lang=l.id_lang
	WHERE l.lang_default = 1
	ORDER BY ty_ve_l.id_type_version ASC;
	
	/* Comprobar si la consulta anterior devolvió filas.
	Si FOUND_ROWS() = 0, significa que no se encontró.
	*/
	IF FOUND_ROWS() = 0 THEN
		SELECT 1 AS ERRNO;
	END IF;
	
	/* Si FOUND_ROWS() > 0, los datos (con ERRNO 2) ya fueron enviados. */
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `totalImageByCategoryId` (IN `ID_C` INT, IN `ID_LA` INT)   BEGIN
	SELECT count(*) as totalImgByIdTable
	FROM ir_category_lang c_l 
	INNER JOIN ir_category_lang_image_lang c_l_img_l 
		ON c_l.id_category_lang=c_l_img_l.id_category_lang
	WHERE c_l.id_category = ID_C
		AND c_l.id_lang = ID_LA;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateAttributeOrder` (IN `ID_ATTR` INT, IN `SO` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO FROM ir_attribute WHERE id_attribute= ID_ATTR) THEN
		BEGIN
			UPDATE ir_attribute
				SET	sort_attribute 		= SO
					WHERE id_attribute 	= ID_ATTR;
			SELECT 2 AS ERRNO;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateAttributeStatus` (IN `ID_ATTR` INT, IN `ST` TINYINT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_attribute a
			INNER JOIN ir_attribute_lang a_l 
				ON a.id_attribute=a_l.id_attribute
				WHERE a.id_attribute= ID_ATTR) THEN
		BEGIN
			UPDATE ir_attribute a
				INNER JOIN ir_attribute_lang a_l 
					ON a.id_attribute=a_l.id_attribute

				SET	a.s_attribute 				= ST,
					a_l.last_update_attribute_lang 	= CURRENT_TIMESTAMP
					WHERE a.id_attribute 			= ID_ATTR;

			SELECT 2 AS ERRNO;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateCategoryOrder` (IN `ID_C` INT, IN `SO` INT)   BEGIN
	IF EXISTS(SELECT 1 FROM ir_category WHERE id_category = ID_C LIMIT 1) THEN
		
		UPDATE ir_category
			SET	sort_category = SO
			WHERE id_category = ID_C;
			
		SELECT 2 AS ERRNO;
		
	ELSE
		/* Categoría no encontrada */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateCategoryStatus` (IN `ID_C` INT, IN `ST` TINYINT)   BEGIN
	IF EXISTS(SELECT 1
			FROM ir_category c 
			INNER JOIN ir_category_lang c_l 
				ON c.id_category=c_l.id_category
			WHERE c.id_category = ID_C
			LIMIT 1) THEN
		
		UPDATE ir_category c 
		INNER JOIN ir_category_lang c_l 
			ON c.id_category=c_l.id_category
		SET	c.s_category = ST,
			c_l.last_update_category_lang = CURRENT_TIMESTAMP
		WHERE c.id_category = ID_C;

		SELECT 2 AS ERRNO;
		
	ELSE
		/* Categoría no encontrada (o sin idioma) */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEmailUser` (IN `ID_U` INT, IN `EM` VARCHAR(50))   BEGIN
	/* 1. EL ID USUARIO NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_user WHERE id_user = ID_U LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. YA EXISTE EL CORREO CON OTRO USUARIO */
	ELSEIF EXISTS(SELECT 1
				FROM ir_user
				WHERE email_user = CONVERT(EM using utf8mb4) collate utf8mb4_unicode_ci
				AND id_user != ID_U
				LIMIT 1) THEN
		SELECT 2 AS ERRNO;

	/* 3. Todas las validaciones pasaron */
	ELSE
		UPDATE ir_user
			SET 	email_user 		= EM,	
				last_session_user 	= CURRENT_TIMESTAMP
			WHERE id_user 		= ID_U;

		SELECT CONCAT(name_user,' ',last_name_user) AS NOMBRE_COMPLETO,3 AS ERRNO
			FROM ir_user
			WHERE id_user = ID_U;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateImageByImageLangVersionId` (IN `ID_IMG_LA_V` INT, IN `FO` VARCHAR(15), IN `IMG` VARCHAR(70))   BEGIN
	IF EXISTS(SELECT 1 
			FROM ir_image_lang_version img_l_ve 
			INNER JOIN ir_image_lang img_l 
				ON img_l_ve.id_image_lang=img_l.id_image_lang
			INNER JOIN ir_image img
				ON img.id_image=img_l.id_image
			WHERE img_l_ve.id_image_lang_version = ID_IMG_LA_V
			LIMIT 1) THEN
		
		UPDATE ir_image_lang_version img_l_ve 
			INNER JOIN ir_image_lang img_l 
				ON img_l_ve.id_image_lang=img_l.id_image_lang
			INNER JOIN ir_image img
				ON img.id_image=img_l.id_image
			SET 	img_l_ve.image_lang			= IMG,
				img.format_image			= FO,
				img_l.last_update_image_lang		= CURRENT_TIMESTAMP
			WHERE img_l_ve.id_image_lang_version 	= ID_IMG_LA_V;
	
		SELECT 2 AS ERRNO;
		
	ELSE
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateImageOrder` (IN `ID_IMG` INT, IN `SO` INT)   BEGIN
	IF EXISTS(SELECT 1 FROM ir_image WHERE id_image = ID_IMG LIMIT 1) THEN
		
		UPDATE ir_image
			SET	sort_image 	= SO
			WHERE id_image 	= ID_IMG;
			
		SELECT 2 AS ERRNO;
		
	ELSE
		/* Imagen no encontrada */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateImageStatus` (IN `ID_IMG` INT, IN `ST` TINYINT)   BEGIN
	UPDATE ir_image img 
	INNER JOIN ir_image_lang img_l 
		ON img.id_image=img_l.id_image
	SET	img.s_image = ST,
		img_l.last_update_image_lang = CURRENT_TIMESTAMP
	WHERE img.id_image = ID_IMG;
	
	/* Comprobar si el UPDATE afectó a alguna fila */
	IF ROW_COUNT() > 0 THEN
		/* El registro existía y fue actualizado */
		SELECT 2 AS ERRNO;
	ELSE
		/* El registro no existía (ninguna fila fue actualizada) */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateInformationAttribute` (IN `ID_ATTR_LA` INT, IN `TI` VARCHAR(70))   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO
			FROM ir_attribute_lang
				WHERE id_attribute_lang = ID_ATTR_LA) THEN
		BEGIN
			UPDATE ir_attribute_lang
				SET 	title_attribute_lang		= TI,
					last_update_attribute_lang 	= CURRENT_TIMESTAMP
					WHERE id_attribute_lang 	= ID_ATTR_LA;

			SELECT 2 AS ERRNO;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateInformationCategory` (IN `ID_C_LA` INT, IN `HE` VARCHAR(30), IN `TI` VARCHAR(70), IN `SUB_TI` VARCHAR(45), IN `DE_SM` VARCHAR(100), IN `DE_LA` TEXT)   BEGIN
	IF EXISTS(SELECT 1
			FROM ir_category c 
			INNER JOIN ir_category_lang c_l 
				ON c.id_category=c_l.id_category
			WHERE c_l.id_category_lang = ID_C_LA
			LIMIT 1) THEN
		
		UPDATE ir_category c 
		INNER JOIN ir_category_lang c_l 
			ON c.id_category=c_l.id_category
		SET 	c.color_hexadecimal_category = HE,
			c_l.title_category_lang = TI,
			c_l.subtitle_category_lang = SUB_TI,
			c_l.description_small_category_lang = DE_SM,
			c_l.description_large_category_lang = DE_LA,
			c_l.last_update_category_lang = CURRENT_TIMESTAMP
		WHERE c_l.id_category_lang = ID_C_LA;

		SELECT 2 AS ERRNO;
		
	ELSE
		/* Registro no encontrado */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateInformationProductAdditionalInformation` (IN `ID_P_LA_ADD_INF` INT, IN `ID_T_T` INT, IN `TAG` VARCHAR(100), IN `CONT` TEXT, IN `HIPE` TEXT)   BEGIN
	IF EXISTS(SELECT 4 AS ERRNO 
			FROM ir_product_lang_additional_information 
				WHERE id_product_lang_additional_information= ID_P_LA_ADD_INF) THEN

		/*SI EXISTE EL ID TYPE TAG*/
		IF EXISTS(SELECT 4 AS ERRNO FROM ir_type_tag WHERE id_type_tag = ID_T_T) THEN

			/*VALIDAR QUE NO EXISTA REGISTRADO EL TITULO*/
			/*IF NOT EXISTS(SELECT 4 AS ERRNO 
						FROM ir_product_lang_additional_information
							WHERE id_product_lang_additional_information != ID_P_LA_ADD_INF
							AND tag_product_lang_additional_information  = CONVERT(TAG using utf8mb4) collate utf8mb4_bin) THEN*/
				BEGIN
					UPDATE ir_product_lang_additional_information
					SET	id_type_tag 					= ID_T_T,
						tag_product_lang_additional_information 	= TAG,
						content_product_lang_additional_information 	= CONT,
						hyperlink_product_lang_additional_information 	= HIPE
					WHERE 	id_product_lang_additional_information 		= ID_P_LA_ADD_INF;

					SELECT 4 AS ERRNO;
				END;
			/*ELSE
				BEGIN
					SELECT 3 AS ERRNO;
				END;
			END IF;*/
		ELSE
			BEGIN
				SELECT 2 AS ERRNO;
			END;
		END IF;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateInformationProductLang` (IN `ID_T_P` INT, IN `ID_P_LA` INT, IN `ID_U` INT, IN `ID_TA` INT, IN `ID_CU` INT, IN `TI` VARCHAR(150), IN `SUB_TI` VARCHAR(100), IN `PRE` DECIMAL(19,2), IN `BTN_PRE` VARCHAR(50), IN `COL_PRE` VARCHAR(20), IN `BG_COL` TEXT, IN `STOK` INT, IN `REF` VARCHAR(40), IN `FRIENDLY` VARCHAR(200), IN `GE_LI` VARCHAR(600), IN `BTN_GE_LI` VARCHAR(50), IN `DE_SM` TEXT, IN `DE_LA` TEXT, IN `ESPECI` TEXT, IN `CL_PR` VARCHAR(20), IN `CL_UN` VARCHAR(20), IN `ME_TI` VARCHAR(128), IN `ME_DESC` VARCHAR(255), IN `ME_KY` VARCHAR(2000))   BEGIN
	IF EXISTS(SELECT 3 AS ERRNO FROM ir_product_lang WHERE id_product_lang = ID_P_LA) THEN
	
		/*EL TITULO DEL PRODUCTO NO EXISTE*/
		/*IF NOT EXISTS(SELECT 3 AS ERRNO 
				FROM ir_product p
				INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
					WHERE p_l.title_product_lang 	= CONVERT(TI using utf8mb4) collate utf8mb4_unicode_ci
					AND p.id_user 			= ID_U
					AND p.id_product        	!= p.id_product) THEN*/
			BEGIN
				UPDATE ir_product p 
					INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product

					SET 	p.id_type_product 				= ID_T_P,
						p_l.id_tax_rule 				= ID_TA,
						p_l.id_type_of_currency				= ID_CU,
						p_l.title_product_lang 				= TI,
						p_l.subtitle_product_lang 			= SUB_TI,
						p_l.general_price_product_lang 			= PRE,
						p_l.text_button_general_price_product_lang 	= BTN_PRE,
						p_l.predominant_color_product_lang 		= COL_PRE,
						p_l.background_color_degraded_product_lang 	= BG_COL,
						p_l.general_stock_product_lang 			= STOK,
						p_l.reference_product_lang 			= REF,
						p_l.friendly_url_product_lang 			= FRIENDLY,
						p_l.general_link_product_lang 			= GE_LI,
						p_l.text_button_general_link_product_lang 	= BTN_GE_LI,
						p_l.description_small_product_lang 		= DE_SM,
						p_l.description_large_product_lang 		= DE_LA,
						p_l.special_specifications_product_lang 	= ESPECI,
						p_l.clave_prod_serv_sat_product_lang 		= CL_PR,
						p_l.clave_unidad_sat_product_lang 		= CL_UN,
						p_l.meta_title_product_lang 			= ME_TI,
						p_l.meta_description_product_lang 		= ME_DESC,
						p_l.meta_keywords_product_lang 			= ME_KY,
						p_l.last_update_product_lang 			= CURRENT_TIMESTAMP
							WHERE p_l.id_product_lang 		= ID_P_LA;

				SELECT 3 AS ERRNO;
			END;
		/*ELSE
			BEGIN
				SELECT 2 AS ERRNO;
			END;
		END IF;*/
	ELSE
		/* EL ID_P_LA NO EXISTE */
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateInformationProductPromotion` (IN `ID_P_PRO` INT, IN `ID_TY_PROM` INT, IN `TI` VARCHAR(70), IN `SK` VARCHAR(30), IN `PRE` DECIMAL(19,2), IN `PORC` INT, IN `DE_SM` TEXT, IN `DE_LA` TEXT, IN `LIN` VARCHAR(600), IN `F_ST` DATE, IN `F_EN` DATE)   BEGIN
	IF EXISTS(SELECT 3 AS ERRNO 
			FROM ir_product_lang_promotion
				WHERE id_product_lang_promotion = ID_P_PRO) THEN
		IF NOT EXISTS(SELECT 3 AS ERRNO 
				FROM ir_product_lang_promotion
					WHERE id_product_lang_promotion != ID_P_PRO
					AND title_product_lang_promotion = CONVERT(TI using utf8mb4) collate utf8mb4_unicode_ci) THEN
			BEGIN
				UPDATE ir_product_lang_promotion

					SET 	id_type_promotion 				= ID_TY_PROM,
						title_product_lang_promotion 			= TI,
						sku_product_lang_promotion 			= SK,
						price_discount_product_lang_promotion 		= PRE,
						discount_rate_product_lang_promotion 		= PORC,
						description_small_product_lang_promotion 	= DE_SM,
						description_large_product_lang_promotion 	= DE_LA,
						link_product_lang_promotion 			= LIN,
						start_date_product_lang_promotion 		= F_ST,
						finish_date_product_lang_promotion 		= F_EN,
						last_update_product_lang_promotion 		= CURRENT_TIMESTAMP
							WHERE id_product_lang_promotion 	= ID_P_PRO;

				SELECT 3 AS ERRNO;
			END;
		ELSE
			/* YA EXISTE EL TITULO DE LA PROMOCION */
			BEGIN
				SELECT 2 AS ERRNO;
			END;
		END IF;

	ELSE
		/* ID_P_PRO NO EXISTE */
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateInformationSlider` (IN `ID_LA` INT, IN `ID_IMG_LA` INT, IN `ID_M` INT, IN `WI` INT, IN `HE` INT, IN `TI` VARCHAR(70), IN `SUB_TI` VARCHAR(45), IN `DE_SM` VARCHAR(400), IN `DE_LA` TEXT, IN `TI_LI` VARCHAR(100), IN `LI` VARCHAR(255), IN `ALT` VARCHAR(100), IN `BGC` VARCHAR(30), IN `BGCD` TEXT, IN `BGR` VARCHAR(15), IN `BGP` VARCHAR(20), IN `BGS` VARCHAR(15))   BEGIN
	IF EXISTS(SELECT 1 
			FROM ir_image img 
			INNER JOIN ir_menu_image m_img 
				ON m_img.id_image=img.id_image
			INNER JOIN ir_image_lang img_l 
				ON img.id_image=img_l.id_image
			WHERE img_l.id_image_lang = ID_IMG_LA
				AND img_l.id_lang = ID_LA
			LIMIT 1) THEN
		
		UPDATE ir_image img 
			INNER JOIN ir_menu_image m_img 
				ON m_img.id_image=img.id_image
			INNER JOIN ir_image_lang img_l 
				ON img.id_image=img_l.id_image
			SET 	img.width_image						= WI,
				img.height_image					= HE,
				img_l.title_image_lang				= TI,
				img_l.subtitle_image_lang			= SUB_TI,
				img_l.description_small_image_lang 		= DE_SM,
				img_l.description_large_image_lang 		= DE_LA,
				img_l.title_hyperlink_image_lang		= TI_LI,
				img_l.link_image_lang				= LI,
				img_l.alt_image_lang				= ALT,
				img_l.background_color_image_lang 		= BGC,
				img_l.background_color_degraded_image_lang 	= BGCD,
				img_l.background_repeat_image_lang 		= BGR,
				img_l.background_position_image_lang 		= BGP,
				img_l.background_size_image_lang 		= BGS,
				img_l.last_update_image_lang 			= CURRENT_TIMESTAMP,
				m_img.id_menu 					= ID_M
			WHERE img_l.id_image_lang 				= ID_IMG_LA
				AND img_l.id_lang 				= ID_LA;

		SELECT 2 AS ERRNO;
		
	ELSE
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateInformationUser` (IN `ID_U` INT, IN `ID_R` INT, IN `NO` VARCHAR(50), IN `L_N` VARCHAR(50), IN `RF` VARCHAR(13), IN `CU` VARCHAR(18), IN `MI` VARCHAR(25), IN `ABO` TEXT, IN `BIOGRA` TEXT, IN `BI` DATE, IN `AG` INT, IN `GE` VARCHAR(5), IN `LA_TE` VARCHAR(7), IN `TE` VARCHAR(25), IN `LA_CE` VARCHAR(7), IN `CE` VARCHAR(25), IN `E` VARCHAR(50), IN `SHIP` VARCHAR(200), IN `AD` VARCHAR(70), IN `CO` VARCHAR(30), IN `ST` VARCHAR(25), IN `CI` VARCHAR(30), IN `MUN` VARCHAR(30), IN `COLO` VARCHAR(30), IN `CP` VARCHAR(7), IN `STREET` VARCHAR(30), IN `N_EX` VARCHAR(10), IN `N_IN` VARCHAR(10), IN `STREET1` VARCHAR(30), IN `STREET2` VARCHAR(30), IN `OT_REF` VARCHAR(50), IN `NA` VARCHAR(20), IN `FIL` TEXT, IN `U_NA` VARCHAR(20))   BEGIN
	/* 1. EL ID USUARIO NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_user WHERE id_user = ID_U LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. EL ID ROL NO EXISTE */
	ELSEIF NOT EXISTS(SELECT 1 FROM ir_role WHERE id_role = ID_R LIMIT 1) THEN
		SELECT 2 AS ERRNO;

	/* 3. EL RFC YA EXISTE (EN OTRO USUARIO) */
	ELSEIF EXISTS(SELECT 1 
			FROM ir_user 
			WHERE rfc_user = CONVERT(RF using utf8mb4) collate utf8mb4_unicode_ci
			AND id_user != ID_U
			LIMIT 1) THEN
		SELECT 3 AS ERRNO;

	/* 4. LA CURP YA EXISTE (EN OTRO USUARIO) */
	ELSEIF EXISTS(SELECT 1
			FROM ir_user 
			WHERE curp_user = CONVERT(CU using utf8mb4) collate utf8mb4_unicode_ci
			AND id_user != ID_U
			LIMIT 1) THEN
		SELECT 4 AS ERRNO;

	/* 5. EL NÚMERO DE MIEMBRO YA EXISTE (EN OTRO USUARIO) */
	ELSEIF EXISTS(SELECT 1
			FROM ir_user 
			WHERE membership_number_user = CONVERT(MI using utf8mb4) collate utf8mb4_unicode_ci
			AND id_user != ID_U
			LIMIT 1) THEN
		SELECT 5 AS ERRNO;

	/* 6. EL USERNAME YA EXISTE (EN OTRO USUARIO) */
	ELSEIF EXISTS(SELECT 1
			FROM ir_user 
			WHERE username_website = CONVERT(U_NA using utf8mb4) collate utf8mb4_unicode_ci
			AND id_user != ID_U
			LIMIT 1) THEN
		SELECT 6 AS ERRNO;
		
	/* 7. Todas las validaciones pasaron */
	ELSE
		UPDATE ir_user
		SET 	id_role 			= ID_R,
			name_user 			= NO,
			last_name_user 			= L_N,
			rfc_user 			= RF,
			curp_user 			= CU,
			membership_number_user 		= MI,
			about_me_user	 		= ABO,
			biography_user	 		= BIOGRA,
			birthdate_user 			= BI,
			age_user 			= AG,
			gender_user 			= GE,
			lada_telephone_user 		= LA_TE,
			telephone_user 			= TE,
			lada_cell_phone_user 		= LA_CE,
			cell_phone_user 		= CE,
			ship_address_user 		= SHIP,
			address_user 			= AD,
			country_user 			= CO,
			state_user 			= ST,
			city_user 			= CI,
			municipality_user		= MUN,
			colony_user			= COLO,
			cp_user 			= CP,
			street_user 			= STREET,
			outdoor_number_user 		= N_EX,
			interior_number_user 		= N_IN,
			between_street1_user 		= STREET1,
			between_street2_user 		= STREET2,
			other_references_user 		= OT_REF,
			nationality_user 		= NA,
			filters_user 			= FIL,
			username_website 		= U_NA,
			last_session_user 		= CURRENT_TIMESTAMP
		WHERE id_user 			= ID_U;

		SELECT 7 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateInformationUserFront` (IN `ID_U` INT, IN `NO` VARCHAR(50), IN `L_N` VARCHAR(50), IN `RF` VARCHAR(13), IN `CU` VARCHAR(18), IN `MI` VARCHAR(25), IN `ABO` TEXT, IN `BIOGRA` TEXT, IN `BI` DATE, IN `AG` INT, IN `GE` VARCHAR(5), IN `LA_TE` VARCHAR(7), IN `TE` VARCHAR(25), IN `LA_CE` VARCHAR(7), IN `CE` VARCHAR(25), IN `E` VARCHAR(50), IN `SHIP` VARCHAR(200), IN `AD` VARCHAR(70), IN `CO` VARCHAR(30), IN `ST` VARCHAR(25), IN `CI` VARCHAR(30), IN `MUN` VARCHAR(30), IN `COLO` VARCHAR(30), IN `CP` VARCHAR(7), IN `STREET` VARCHAR(30), IN `N_EX` VARCHAR(10), IN `N_IN` VARCHAR(10), IN `STREET1` VARCHAR(30), IN `STREET2` VARCHAR(30), IN `OT_REF` VARCHAR(50), IN `NA` VARCHAR(20), IN `U_NA` VARCHAR(20))   BEGIN
	/* 1. EL ID USUARIO NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_user WHERE id_user = ID_U LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. EL RFC YA EXISTE (EN OTRO USUARIO) */
	ELSEIF EXISTS(SELECT 1 
			FROM ir_user 
			WHERE rfc_user = CONVERT(RF using utf8mb4) collate utf8mb4_unicode_ci
			AND id_user != ID_U
			LIMIT 1) THEN
		SELECT 2 AS ERRNO;

	/* 3. LA CURP YA EXISTE (EN OTRO USUARIO) */
	ELSEIF EXISTS(SELECT 1
			FROM ir_user 
			WHERE curp_user = CONVERT(CU using utf8mb4) collate utf8mb4_unicode_ci
			AND id_user != ID_U
			LIMIT 1) THEN
		SELECT 3 AS ERRNO;

	/* 4. EL NÚMERO DE MIEMBRO YA EXISTE (EN OTRO USUARIO) */
	ELSEIF EXISTS(SELECT 1
			FROM ir_user 
			WHERE membership_number_user = CONVERT(MI using utf8mb4) collate utf8mb4_unicode_ci
			AND id_user != ID_U
			LIMIT 1) THEN
		SELECT 4 AS ERRNO;

	/* 5. EL USERNAME YA EXISTE (EN OTRO USUARIO) */
	ELSEIF EXISTS(SELECT 1
			FROM ir_user 
			WHERE username_website = CONVERT(U_NA using utf8mb4) collate utf8mb4_unicode_ci
			AND id_user != ID_U
			LIMIT 1) THEN
		SELECT 5 AS ERRNO;
		
	/* 6. Todas las validaciones pasaron */
	ELSE
		UPDATE ir_user
		SET 	name_user 			= NO,
			last_name_user 			= L_N,
			rfc_user 			= RF,
			curp_user 			= CU,
			membership_number_user 		= MI,
			about_me_user	 		= ABO,
			biography_user	 		= BIOGRA,
			birthdate_user 			= BI,
			age_user 			= AG,
			gender_user 			= GE,
			lada_telephone_user 		= LA_TE,
			telephone_user 			= TE,
			lada_cell_phone_user 		= LA_CE,
			cell_phone_user 		= CE,
			ship_address_user 		= SHIP,
			address_user 			= AD,
			country_user 			= CO,
			state_user 			= ST,
			city_user 			= CI,
			municipality_user		= MUN,
			colony_user			= COLO,
			cp_user 			= CP,
			street_user 			= STREET,
			outdoor_number_user 		= N_EX,
			interior_number_user 		= N_IN,
			between_street1_user 		= STREET1,
			between_street2_user 		= STREET2,
			other_references_user 		= OT_REF,
			nationality_user 		= NA,
			username_website 		= U_NA,
			last_session_user 		= CURRENT_TIMESTAMP
		WHERE id_user 			= ID_U;

		SELECT 6 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateInformationUserSocialMedia` (IN `ID_U_SM` INT, IN `ID_SM` INT, IN `URL` VARCHAR(600))   BEGIN
	DECLARE ICO varchar(45);

	/* 1. EL ID USUARIO SOCIAL MEDIA NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_user_social_media WHERE id_user_social_media = ID_U_SM LIMIT 1) THEN
		SELECT 1 AS ERRNO;
	ELSE
		SELECT icon_social_media INTO ICO
		FROM ir_social_media 
		WHERE id_social_media = ID_SM
		LIMIT 1;

		/* 3. EL ID SOCIAL MEDIA NO EXISTE */
		IF ICO IS NULL THEN
			SELECT 2 AS ERRNO;
		ELSE
			/* 4. Ambos IDs son válidos y ya tenemos el ícono. */
			UPDATE ir_user_social_media
				SET 	id_social_media 		= ID_SM,
					url_user_social_media 		= URL,
					last_user_social_media 		= CURRENT_TIMESTAMP
				WHERE id_user_social_media 	= ID_U_SM;

			SELECT ICO, 3 AS ERRNO;
		END IF;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updatePasswordUser` (IN `ID_U` INT, IN `PA` CHAR(128), IN `SA` CHAR(128))   BEGIN
	IF EXISTS(SELECT 1 FROM ir_user WHERE id_user = ID_U LIMIT 1) THEN
		
		UPDATE ir_user
			SET 	password_user 		= PA,
				salt_user 		= SA,
				last_session_user 	= CURRENT_TIMESTAMP
			WHERE 	id_user 		= ID_U;
	
		SELECT CONCAT(name_user,' ',last_name_user) AS NOMBRE_COMPLETO,email_user AS EMAIL,2 AS ERRNO
			FROM ir_user
			WHERE id_user = ID_U;
			
	ELSE
		/*EL ID USUARIO NO EXISTE*/
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updatePriceDiscountProductPromotion` (IN `ID_P_PRO` INT, IN `PRE` DECIMAL(19,2))   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_product_lang_promotion
				WHERE id_product_lang_promotion = ID_P_PRO) THEN
		BEGIN
			UPDATE ir_product_lang_promotion

				SET 	price_discount_product_lang_promotion 	= PRE,
					last_update_product_lang_promotion 	= CURRENT_TIMESTAMP
						WHERE id_product_lang_promotion = ID_P_PRO;

			SELECT 2 AS ERRNO;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateProductAdditionalInformationOrder` (IN `ID_P_LA_ADD_INF` INT, IN `SO` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_product_lang_additional_information
				WHERE id_product_lang_additional_information = ID_P_LA_ADD_INF) THEN
		BEGIN
			UPDATE ir_product_lang_additional_information
				SET	sort_product_lang_additional_information	= SO
				WHERE id_product_lang_additional_information 		= ID_P_LA_ADD_INF;

			SELECT 2 AS ERRNO;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateProductOrder` (IN `ID_P` INT, IN `SO` INT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO FROM ir_product WHERE id_product= ID_P) THEN
		BEGIN
			UPDATE ir_product
				SET	sort_product 	= SO
				WHERE 	id_product 	= ID_P;

			SELECT 2 AS ERRNO;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateProductStatus` (IN `ID_P` INT, IN `ST` TINYINT)   BEGIN
	IF EXISTS(SELECT 4 AS ERRNO 
			FROM ir_product_lang
				WHERE id_product = ID_P) THEN

		/*VALIDAR QUE TENGA POR LO MENOS UNA CATEGORIA ASOCIADA*/
		IF EXISTS(SELECT 4 AS ERRNO FROM ir_product_category WHERE id_product = ID_P) THEN

			/*ACTIVAR SOLO SI TIENE UNA IMAGEN (PORTADA)*/
			IF EXISTS(SELECT 4 AS ERRNO 
					FROM ir_product_lang_image_lang p_l_img_l
					INNER JOIN ir_product_lang p_l 
						ON p_l_img_l.id_product_lang=p_l.id_product_lang
						WHERE p_l.id_product = ID_P) THEN
				BEGIN
					UPDATE ir_product p
						INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
						SET	p.s_product 			= ST,
							p_l.last_update_product_lang 	= CURRENT_TIMESTAMP
							WHERE p.id_product 		= ID_P;

					SELECT 4 AS ERRNO;
				END;
			ELSE
				/*ACTIVAR SOLO SI TIENE UNA IMAGEN (PRESENTACION)*/
				IF EXISTS(SELECT 4 AS ERRNO 
						FROM ir_product_lang_presentation p_l_pre
						INNER JOIN ir_product_lang p_l ON p_l_pre.id_product_lang=p_l.id_product_lang
							WHERE p_l.id_product = ID_P) THEN
					BEGIN
						UPDATE ir_product p
							INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
							SET	p.s_product 			= ST,
								p_l.last_update_product_lang 	= CURRENT_TIMESTAMP
								WHERE p.id_product 		= ID_P;

						SELECT 4 AS ERRNO;
					END;
				ELSE
					BEGIN
						/*NO TIENE IMAGEN REGISTRADA*/
						SELECT 3 AS ERRNO;
					END;
				END IF;
			END IF;
		ELSE
			BEGIN
				/*NO TIENE CATEGORIA ASOCIADA*/
				SELECT 2 AS ERRNO;
			END;
		END IF;
	ELSE
		BEGIN
			/*ID_P NO EXISTE*/
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateProductStatusVisibleHome` (IN `ID_P` INT, IN `ST_V` TINYINT)   BEGIN
	IF EXISTS(SELECT 4 AS ERRNO 
			FROM ir_product_lang
				WHERE id_product = ID_P) THEN

		/*VALIDAR QUE TENGA POR LO MENOS UNA CATEGORIA ASOCIADA*/
		IF EXISTS(SELECT 4 AS ERRNO FROM ir_product_category WHERE id_product = ID_P) THEN

			/*ACTIVAR SOLO SI TIENE UNA IMAGEN (PORTADA)*/
			IF EXISTS(SELECT 4 AS ERRNO 
					FROM ir_product_lang_image_lang p_l_img_l
					INNER JOIN ir_product_lang p_l 
						ON p_l_img_l.id_product_lang=p_l.id_product_lang
						WHERE p_l.id_product = ID_P) THEN
				BEGIN
					UPDATE ir_product p
						INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
						SET	p.s_product_visible 		= ST_V,
							p_l.last_update_product_lang 	= CURRENT_TIMESTAMP
							WHERE p.id_product 		= ID_P;

					SELECT 4 AS ERRNO;
				END;
			ELSE
				/*ACTIVAR SOLO SI TIENE UNA IMAGEN (PRESENTACION)*/
				IF EXISTS(SELECT 4 AS ERRNO 
						FROM ir_product_lang_presentation p_l_pre
						INNER JOIN ir_product_lang p_l ON p_l_pre.id_product_lang=p_l.id_product_lang
							WHERE p_l.id_product = ID_P) THEN
					BEGIN
						UPDATE ir_product p
							INNER JOIN ir_product_lang p_l ON p.id_product=p_l.id_product
							SET	p.s_product_visible 		= ST_V,
								p_l.last_update_product_lang 	= CURRENT_TIMESTAMP
								WHERE p.id_product 		= ID_P;

						SELECT 4 AS ERRNO;
					END;
				ELSE
					BEGIN
						/*NO TIENE IMAGEN REGISTRADA*/	
						SELECT 3 AS ERRNO;
					END;
				END IF;
			END IF;
		ELSE
			BEGIN
				/*NO TIENE CATEGORIA ASOCIADA*/	
				SELECT 2 AS ERRNO;
			END;
		END IF;
	ELSE
		BEGIN
			/*ID_P NO EXISTE*/
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateStatusProductAdditionalInformation` (IN `ID_P_LA_ADD_INF` INT, IN `ST` TINYINT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_product_lang_additional_information 
				WHERE id_product_lang_additional_information = ID_P_LA_ADD_INF) THEN
		BEGIN
			UPDATE ir_product_lang_additional_information
				SET	s_visible_product_lang_additional_information 	= ST
				WHERE 	id_product_lang_additional_information 		= ID_P_LA_ADD_INF;

			SELECT 2 AS ERRNO;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateStatusProductPromotions` (IN `ID_P_LA_PROM` INT, IN `ST` TINYINT)   BEGIN
	/*
	ST
	   0 = Desactivo
	   1 = Activo
	*/
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_product_lang_promotion
				WHERE id_product_lang_promotion = ID_P_LA_PROM) THEN
		BEGIN
			IF (ST = 1) THEN
				/*ACTIVAR PROMOCION POR PARTE DEL USUARIO Y MANDAR CORREO AL ADMINISTRADOR*/
				BEGIN
					UPDATE ir_product_lang_promotion
						SET	s_product_lang_promotion 	= 1
						WHERE 	id_product_lang_promotion 	= ID_P_LA_PROM;
				END;
			ELSE
				/*DESACTIVAR PROMOCION POR PARTE DEL USUARIO*/
				BEGIN
					UPDATE ir_product_lang_promotion
						SET	s_product_lang_promotion 	 = 0
						WHERE 	id_product_lang_promotion 	 = ID_P_LA_PROM;
				END;
			END IF;

			SELECT p_l.id_product,p_l.title_product_lang,2 AS ERRNO
				FROM ir_product_lang p_l
				INNER JOIN ir_product_lang_promotion p_l_pro ON p_l.id_product_lang=p_l_pro.id_product_lang
					WHERE id_product_lang_promotion = ID_P_LA_PROM;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateStatusVisibleProductPromotions` (IN `ID_P_LA_PROM` INT, IN `ST_V` TINYINT)   BEGIN
	IF EXISTS(SELECT 2 AS ERRNO 
			FROM ir_product_lang_promotion
				WHERE id_product_lang_promotion = ID_P_LA_PROM) THEN
		BEGIN
			UPDATE ir_product_lang_promotion
				SET	s_visible_product_lang_promotion 	= ST_V
				WHERE 	id_product_lang_promotion 		= ID_P_LA_PROM;

			SELECT p_l.id_product,p_l.title_product_lang,2 AS ERRNO
				FROM ir_product_lang p_l
				INNER JOIN ir_product_lang_promotion p_l_pro ON p_l.id_product_lang=p_l_pro.id_product_lang
					WHERE id_product_lang_promotion = ID_P_LA_PROM;
		END;
	ELSE
		BEGIN
			SELECT 1 AS ERRNO;
		END;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUserLastSession` (IN `ID_U` INT)   BEGIN
	IF EXISTS(SELECT 1 FROM ir_user WHERE id_user = ID_U LIMIT 1) THEN
		
		UPDATE ir_user
			SET 	last_session_user	= CURRENT_TIMESTAMP
			WHERE id_user 		= ID_U;

		SELECT 2 AS ERRNO;
		
	ELSE
		/* Usuario no encontrado */
		SELECT 1 AS ERRNO;
	END IF;	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUserProfilePicture` (IN `ID_U` INT, IN `IMG` VARCHAR(70))   BEGIN
	IF EXISTS(SELECT 1 FROM ir_user WHERE id_user = ID_U LIMIT 1) THEN
		
		UPDATE ir_user
			SET 	profile_photo_user 	= IMG,
				last_session_user	= CURRENT_TIMESTAMP
			WHERE 	id_user 		= ID_U;

		SELECT 2 AS ERRNO;
		
	ELSE
		/* Usuario no encontrado */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUserStatus` (IN `ID_U` INT, IN `ST` TINYINT)   BEGIN
	IF EXISTS(SELECT 1 FROM ir_user WHERE id_user = ID_U LIMIT 1) THEN
		
		UPDATE ir_user
			SET	s_user			= ST,
				last_session_user 	= CURRENT_TIMESTAMP
			WHERE id_user 		= ID_U;
			
		SELECT 2 AS ERRNO;
		
	ELSE
		/* Usuario no encontrado */
		SELECT 1 AS ERRNO;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUserTheme` (IN `ID_U` INT, IN `ID_C` INT)   BEGIN
	/* 1. EL ID USER NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_user WHERE id_user = ID_U LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. EL ID CUSTOMIZE NO EXISTE */
	ELSEIF NOT EXISTS(SELECT 1 FROM ir_customize_lang WHERE id_customize = ID_C LIMIT 1) THEN
		SELECT 2 AS ERRNO;

	/* 3. El usuario y el tema existen. Proceder con UPDATE o INSERT */
	ELSE
		INSERT INTO ir_user_customize (id_user_customize, id_customize, id_user, last_user_customize)
		VALUES (NULL, ID_C, ID_U, CURRENT_TIMESTAMP)
		ON DUPLICATE KEY UPDATE
			id_customize = ID_C,
			last_user_customize = CURRENT_TIMESTAMP;

		/* ROW_COUNT() = 1 significa que se hizo un INSERT (ERRNO 3)
		ROW_COUNT() = 2 (o 0) significa que se hizo un UPDATE (ERRNO 4)
		*/
		IF ROW_COUNT() = 1 THEN
			/* REGISTRAR TEMA*/
			SELECT 3 AS ERRNO;
		ELSE
			/* MODIFICAR TEMA */
			SELECT 4 AS ERRNO;
		END IF;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateUserThemeAndColor` (IN `ID_U` INT, IN `ID_C` INT, IN `CO` VARCHAR(10), IN `TXT_1` VARCHAR(100))   BEGIN
	DECLARE v_action INT DEFAULT 0;

	/* Manejador de errores para revertir la transacción */
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		SELECT -99 AS ERRNO;
	END;

	/* 1. EL ID USER NO EXISTE */
	IF NOT EXISTS(SELECT 1 FROM ir_user WHERE id_user = ID_U LIMIT 1) THEN
		SELECT 1 AS ERRNO;
		
	/* 2. EL ID CUSTOMIZE NO EXISTE */
	ELSEIF NOT EXISTS(SELECT 1 FROM ir_customize_lang WHERE id_customize = ID_C LIMIT 1) THEN
		SELECT 2 AS ERRNO;
		
	/* 3. El usuario y el tema existen */
	ELSE
		/* Iniciar transacción para integridad de datos */
		START TRANSACTION;

		/* Actualizar los colores/texto del tema */
		UPDATE ir_customize_lang
		SET	color_customize_lang = CO,
			text_block_1_customize_lang = TXT_1
		WHERE id_customize = ID_C;

		/* Asignar el tema al usuario (UPSERT)
		   (Asume que 'id_user' es una CLAVE ÚNICA en 'ir_user_customize')
		*/
		INSERT INTO ir_user_customize (id_user_customize, id_customize, id_user, last_user_customize)
		VALUES (NULL, ID_C, ID_U, CURRENT_TIMESTAMP)
		ON DUPLICATE KEY UPDATE
			id_customize = ID_C,
			last_user_customize = CURRENT_TIMESTAMP;

		/* Capturar la acción para la lógica de retorno
		   ROW_COUNT() = 1 significa que se hizo un INSERT
		   ROW_COUNT() = 2 (o 0) significa que se hizo un UPDATE
		*/
		IF ROW_COUNT() = 1 THEN
			SET v_action = 1; /* 1 = REGISTRAR (INSERT) */
		ELSE
			SET v_action = 2; /* 2 = MODIFICAR (UPDATE) */
		END IF;
		
		/* Confirmar transacción */
		COMMIT;

		SELECT v_action AS ACTION, 3 AS ERRNO;
	END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `ir_api_factura`
--

CREATE TABLE `ir_api_factura` (
  `ir_api_factura` int NOT NULL,
  `token_api_factura` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `usuario_api_factura` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `contrasenia_api_factura` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `rfc_emisor_api_factura` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `ubicacion_api_factura` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email_api_factura` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_attribute`
--

CREATE TABLE `ir_attribute` (
  `id_attribute` int NOT NULL,
  `id_user` int NOT NULL,
  `parent_id_attribute` int NOT NULL DEFAULT '0',
  `sort_attribute` int NOT NULL DEFAULT '0',
  `s_attribute` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_attribute`
--

INSERT INTO `ir_attribute` (`id_attribute`, `id_user`, `parent_id_attribute`, `sort_attribute`, `s_attribute`) VALUES
(1, 1, 0, 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_attribute_lang`
--

CREATE TABLE `ir_attribute_lang` (
  `id_attribute_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_attribute` int NOT NULL,
  `title_attribute_lang` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_update_attribute_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `s_attribute_lang_visible` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_attribute_lang`
--

INSERT INTO `ir_attribute_lang` (`id_attribute_lang`, `id_lang`, `id_attribute`, `title_attribute_lang`, `last_update_attribute_lang`, `s_attribute_lang_visible`) VALUES
(1, 1, 1, 'General', '2025-11-09 03:30:38', 1),
(2, 2, 1, 'General', '2025-11-09 03:30:38', 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_category`
--

CREATE TABLE `ir_category` (
  `id_category` int NOT NULL,
  `id_user` int NOT NULL,
  `parent_id` int NOT NULL DEFAULT '0',
  `sort_category` int NOT NULL DEFAULT '0',
  `color_hexadecimal_category` varchar(30) COLLATE utf8mb4_bin DEFAULT NULL,
  `s_category` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_category`
--

INSERT INTO `ir_category` (`id_category`, `id_user`, `parent_id`, `sort_category`, `color_hexadecimal_category`, `s_category`) VALUES
(1, 1, 0, 0, '#000000', 1),
(2, 1, 0, 0, '#000000', 1),
(3, 1, 0, 0, '#000000', 1),
(4, 1, 0, 0, '#000000', 1),
(5, 1, 2, 0, '#ffffff', 1),
(6, 1, 3, 0, '#ffffff', 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_category_lang`
--

CREATE TABLE `ir_category_lang` (
  `id_category_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_category` int NOT NULL,
  `title_category_lang` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtitle_category_lang` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description_small_category_lang` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description_large_category_lang` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `last_update_category_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `s_category_lang_visible` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_category_lang`
--

INSERT INTO `ir_category_lang` (`id_category_lang`, `id_lang`, `id_category`, `title_category_lang`, `subtitle_category_lang`, `description_small_category_lang`, `description_large_category_lang`, `last_update_category_lang`, `s_category_lang_visible`) VALUES
(1, 1, 1, 'Inicio', '', '', '', '2025-11-09 03:30:38', 1),
(2, 2, 1, 'Home', '', '', '', '2025-11-09 03:30:38', 1),
(3, 1, 2, 'Categorías', '', '', '', '2025-11-09 03:30:38', 1),
(4, 2, 2, 'Categories', '', '', '', '2025-11-09 03:30:38', 1),
(5, 1, 3, 'Marcas', '', '', '', '2025-11-09 03:30:38', 1),
(6, 2, 3, 'Brand', '', '', '', '2025-11-09 03:30:38', 1),
(7, 1, 4, 'Blog', '', '', '', '2025-11-09 03:30:38', 1),
(8, 2, 4, 'Blog', '', '', '', '2025-11-09 03:30:38', 1),
(9, 1, 5, 'Semi-nuevo', NULL, NULL, NULL, '2025-11-22 02:45:30', 1),
(10, 2, 5, 'Semi-nuevo', NULL, NULL, NULL, '2025-11-22 02:45:30', 1),
(12, 1, 6, 'Huawei', NULL, NULL, NULL, '2025-11-22 02:46:20', 1),
(13, 2, 6, 'Huawei', NULL, NULL, NULL, '2025-11-22 02:46:20', 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_category_lang_image_lang`
--

CREATE TABLE `ir_category_lang_image_lang` (
  `id_category_lang_image_lang` int NOT NULL,
  `id_category_lang` int NOT NULL,
  `id_image_section_lang` int NOT NULL,
  `id_image_lang` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_customize`
--

CREATE TABLE `ir_customize` (
  `id_customize` int NOT NULL,
  `id_type_customize` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_customize`
--

INSERT INTO `ir_customize` (`id_customize`, `id_type_customize`) VALUES
(1, 1),
(2, 1),
(3, 1),
(4, 1),
(5, 1),
(6, 1),
(7, 1),
(8, 1),
(9, 1),
(10, 1),
(11, 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_customize_lang`
--

CREATE TABLE `ir_customize_lang` (
  `id_customize_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_customize` int NOT NULL,
  `name_customize_lang` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `background_image_customize_lang` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `background_color_customize_lang` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `color_customize_lang` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `text_block_1_customize_lang` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_customize_lang`
--

INSERT INTO `ir_customize_lang` (`id_customize_lang`, `id_lang`, `id_customize`, `name_customize_lang`, `background_image_customize_lang`, `background_color_customize_lang`, `color_customize_lang`, `text_block_1_customize_lang`) VALUES
(1, 1, 1, 'Fondo 1', 'fondo_1_ESP.jpg', '', '#ed5f1e', 'Cambia hoy tu estilo de vida'),
(2, 2, 1, 'Background 1', 'fondo_1_ENG.jpg', '', '#ed5f1e', 'Change your lifestyle today'),
(3, 1, 2, 'Fondo 2', 'fondo_2_ESP.jpg', '', '#ed5f1e', 'Cambia hoy tu estilo de vida'),
(4, 2, 2, 'Background 2', 'fondo_2_ENG.jpg', '', '#ed5f1e', 'Change your lifestyle today'),
(5, 1, 3, 'Fondo 3', 'fondo_3_ESP.jpg', '', '#ed5f1e', 'Cambia hoy tu estilo de vida'),
(6, 2, 3, 'Background 3', 'fondo_3_ENG.jpg', '', '#ed5f1e', 'Change your lifestyle today'),
(7, 1, 4, 'Fondo 4', 'fondo_4_ESP.jpg', '', '#ed5f1e', 'Cambia hoy tu estilo de vida'),
(8, 2, 4, 'Background 4', 'fondo_4_ENG.jpg', '', '#ed5f1e', 'Change your lifestyle today'),
(9, 1, 5, 'Fondo 5', 'fondo_5_ESP.jpg', '', '#ed5f1e', 'Cambia hoy tu estilo de vida'),
(10, 2, 5, 'Background 5', 'fondo_5_ENG.jpg', '', '#ed5f1e', 'Change your lifestyle today'),
(11, 1, 6, 'Fondo 6', 'fondo_6_ESP.jpg', '', '#ed5f1e', 'Cambia hoy tu estilo de vida'),
(12, 2, 6, 'Background 6', 'fondo_6_ENG.jpg', '', '#ed5f1e', 'Change your lifestyle today'),
(13, 1, 7, 'Fondo 7', 'fondo_7_ESP.jpg', '', '#ed5f1e', 'Cambia hoy tu estilo de vida'),
(14, 2, 7, 'Background 7', 'fondo_7_ENG.jpg', '', '#ed5f1e', 'Change your lifestyle today'),
(15, 1, 8, 'Fondo 8', 'fondo_8_ESP.jpg', '', '#ed5f1e', 'Cambia hoy tu estilo de vida'),
(16, 2, 8, 'Background 8', 'fondo_8_ENG.jpg', '', '#ed5f1e', 'Change your lifestyle today'),
(17, 1, 9, 'Fondo 9', 'fondo_9_ESP.jpg', '', '#ed5f1e', 'Cambia hoy tu estilo de vida'),
(18, 2, 9, 'Background 9', 'fondo_9_ENG.jpg', '', '#ed5f1e', 'Change your lifestyle today'),
(19, 1, 10, 'Fondo 10', 'fondo_10_ESP.jpg', '', '#ed5f1e', 'Cambia hoy tu estilo de vida'),
(20, 2, 10, 'Background 10', 'fondo_10_ENG.jpg', '', '#ed5f1e', 'Change your lifestyle today'),
(21, 1, 11, 'Fondo 11', 'fondo_11_ESP.jpg', '', '#ed5f1e', 'Cambia hoy tu estilo de vida'),
(22, 2, 11, 'Background 11', 'fondo_11_ENG.jpg', '', '#ed5f1e', 'Change your lifestyle today');

-- --------------------------------------------------------

--
-- Table structure for table `ir_file`
--

CREATE TABLE `ir_file` (
  `id_file` int NOT NULL,
  `format_file` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `size_file` int NOT NULL DEFAULT '0',
  `parent_file` int DEFAULT '0',
  `sort_file` int DEFAULT '0',
  `s_file` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_file_lang`
--

CREATE TABLE `ir_file_lang` (
  `id_file_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_file` int NOT NULL,
  `title_file_lang` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `attached_file_lang` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `link_file_lang` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_update_file_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `s_file_lang_visible` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_image`
--

CREATE TABLE `ir_image` (
  `id_image` int NOT NULL,
  `id_type_image` int NOT NULL,
  `width_image` int NOT NULL DEFAULT '0',
  `height_image` int NOT NULL DEFAULT '0',
  `format_image` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `size_image` int NOT NULL DEFAULT '0',
  `parent_image` int NOT NULL DEFAULT '0',
  `sort_image` int NOT NULL DEFAULT '0',
  `s_image` tinyint NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_image`
--

INSERT INTO `ir_image` (`id_image`, `id_type_image`, `width_image`, `height_image`, `format_image`, `size_image`, `parent_image`, `sort_image`, `s_image`) VALUES
(1, 15, 0, 0, 'image/png', 6416, 0, 0, 1),
(2, 6, 0, 0, 'image/png', 11859, 0, 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_image_lang`
--

CREATE TABLE `ir_image_lang` (
  `id_image_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_image` int NOT NULL,
  `title_image_lang` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtitle_image_lang` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description_small_image_lang` varchar(400) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description_large_image_lang` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `title_hyperlink_image_lang` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `link_image_lang` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `alt_image_lang` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `background_color_image_lang` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `background_color_degraded_image_lang` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `background_repeat_image_lang` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `background_position_image_lang` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `background_size_image_lang` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_update_image_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `s_image_lang_visible` tinyint NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_image_lang`
--

INSERT INTO `ir_image_lang` (`id_image_lang`, `id_lang`, `id_image`, `title_image_lang`, `subtitle_image_lang`, `description_small_image_lang`, `description_large_image_lang`, `title_hyperlink_image_lang`, `link_image_lang`, `alt_image_lang`, `background_color_image_lang`, `background_color_degraded_image_lang`, `background_repeat_image_lang`, `background_position_image_lang`, `background_size_image_lang`, `last_update_image_lang`, `s_image_lang_visible`) VALUES
(1, 1, 1, 'Laptop ESP', NULL, NULL, NULL, NULL, NULL, 'Laptop ESP', NULL, NULL, NULL, NULL, NULL, '2025-11-22 02:44:59', 1),
(2, 2, 1, 'Laptop ENG', NULL, NULL, NULL, NULL, NULL, 'Laptop ENG', NULL, NULL, NULL, NULL, NULL, '2025-11-22 02:45:00', 1),
(3, 1, 2, 'Tu día deja huella. Haz que valga.', NULL, NULL, NULL, NULL, NULL, 'LYROZ Tu día deja huella. Haz que valga.', '#0088cc', NULL, NULL, NULL, NULL, '2025-11-22 02:57:03', 1),
(4, 2, 2, 'Tu día deja huella. Haz que valga.', NULL, NULL, NULL, NULL, NULL, 'LYROZ Tu día deja huella. Haz que valga.', '#0088cc', NULL, NULL, NULL, NULL, '2025-11-22 02:57:03', 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_image_lang_version`
--

CREATE TABLE `ir_image_lang_version` (
  `id_image_lang_version` int NOT NULL,
  `id_image_lang` int NOT NULL,
  `s_main_image_lang_version` tinyint NOT NULL,
  `id_type_version` int NOT NULL DEFAULT '1',
  `image_lang` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_image_lang_version`
--

INSERT INTO `ir_image_lang_version` (`id_image_lang_version`, `id_image_lang`, `s_main_image_lang_version`, `id_type_version`, `image_lang`) VALUES
(1, 1, 1, 1, 'e31f925dc55f5e9c40efeb61aecadc36_ESP.png'),
(2, 2, 1, 1, 'e31f925dc55f5e9c40efeb61aecadc36_ENG.png'),
(3, 3, 1, 1, '85b7f12647b11f7856526c24925a3f14_ESP.png'),
(4, 4, 1, 1, '85b7f12647b11f7856526c24925a3f14_ENG.png');

-- --------------------------------------------------------

--
-- Table structure for table `ir_image_section`
--

CREATE TABLE `ir_image_section` (
  `id_image_section` int NOT NULL,
  `parent_image_section` int NOT NULL DEFAULT '0',
  `sort_image_section` int NOT NULL DEFAULT '0',
  `s_image_section` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_image_section`
--

INSERT INTO `ir_image_section` (`id_image_section`, `parent_image_section`, `sort_image_section`, `s_image_section`) VALUES
(1, 0, 0, 1),
(2, 0, 0, 1),
(3, 0, 0, 1),
(4, 0, 0, 1),
(5, 0, 0, 1),
(6, 0, 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_image_section_lang`
--

CREATE TABLE `ir_image_section_lang` (
  `id_image_section_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_image_section` int NOT NULL,
  `name_image_section_lang` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_image_section_lang`
--

INSERT INTO `ir_image_section_lang` (`id_image_section_lang`, `id_lang`, `id_image_section`, `name_image_section_lang`) VALUES
(1, 1, 1, 'Miniatura 1'),
(2, 2, 1, 'Thumbnail 1'),
(3, 1, 2, 'Logo'),
(4, 2, 2, 'Logo'),
(5, 1, 3, 'Banner'),
(6, 2, 3, 'Banner'),
(7, 1, 4, 'Miniatura 2'),
(8, 2, 4, 'Thumbnail 2'),
(9, 1, 5, 'Miniatura menú'),
(10, 2, 5, 'Menu thumbnail'),
(11, 1, 6, 'Lightbox'),
(12, 2, 6, 'Lightbox');

-- --------------------------------------------------------

--
-- Table structure for table `ir_lang`
--

CREATE TABLE `ir_lang` (
  `id_lang` int NOT NULL,
  `lang` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `iso_code` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `lang_cod` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `locale` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_format_lite` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_format_full` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `flag` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `lang_default` tinyint NOT NULL DEFAULT '0',
  `s_lang` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_lang`
--

INSERT INTO `ir_lang` (`id_lang`, `lang`, `iso_code`, `lang_cod`, `locale`, `date_format_lite`, `date_format_full`, `flag`, `lang_default`, `s_lang`) VALUES
(1, 'Español', 'ESP', 'es-ES', 'es-Es', 'd-m-Y', 'd-m-Y H:i:s', 'es.png', 1, 1),
(2, 'English', 'ENG', 'en-US', 'en-US', 'Y-m-d', 'Y-m-d H:i:s', 'en.png', 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_menu`
--

CREATE TABLE `ir_menu` (
  `id_menu` int NOT NULL,
  `parent_menu` int NOT NULL DEFAULT '0',
  `sort_menu` int NOT NULL DEFAULT '0',
  `s_menu` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_menu`
--

INSERT INTO `ir_menu` (`id_menu`, `parent_menu`, `sort_menu`, `s_menu`) VALUES
(1, 0, 0, 1),
(2, 0, 0, 1),
(3, 0, 0, 1),
(4, 0, 0, 1),
(5, 0, 0, 1),
(6, 0, 0, 1),
(7, 0, 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_menu_image`
--

CREATE TABLE `ir_menu_image` (
  `id_menu_image` int NOT NULL,
  `id_menu` int NOT NULL,
  `id_image` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_menu_image`
--

INSERT INTO `ir_menu_image` (`id_menu_image`, `id_menu`, `id_image`) VALUES
(1, 1, 2);

-- --------------------------------------------------------

--
-- Table structure for table `ir_menu_lang`
--

CREATE TABLE `ir_menu_lang` (
  `id_menu_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_menu` int NOT NULL,
  `title_menu_lang` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description_small_menu_lang` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `link_menu_lang` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `link_rewrite_menu_lang` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `meta_title_menu_lang` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `meta_description_menu_lang` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `meta_keywords_menu_lang` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_update_menu_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_menu_lang`
--

INSERT INTO `ir_menu_lang` (`id_menu_lang`, `id_lang`, `id_menu`, `title_menu_lang`, `description_small_menu_lang`, `link_menu_lang`, `link_rewrite_menu_lang`, `meta_title_menu_lang`, `meta_description_menu_lang`, `meta_keywords_menu_lang`, `last_update_menu_lang`) VALUES
(1, 1, 1, 'Inicio', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(2, 2, 1, 'Home', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(3, 1, 2, 'Nosotros', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(4, 2, 2, 'About us', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(5, 1, 3, 'Servicios', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(6, 2, 3, 'Services', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(7, 1, 4, 'Proyectos', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(8, 2, 4, 'Projects', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(9, 1, 5, 'Contacto', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(10, 2, 5, 'Contact', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(11, 1, 6, 'Productos', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(12, 2, 6, 'Products', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(13, 1, 7, 'Blog', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38'),
(14, 2, 7, 'Blog', '', '', '', 'Iridizen', 'Iridizen', 'Iridizen', '2025-11-09 03:30:38');

-- --------------------------------------------------------

--
-- Table structure for table `ir_product`
--

CREATE TABLE `ir_product` (
  `id_product` int NOT NULL,
  `id_user` int NOT NULL,
  `id_type_product` int NOT NULL,
  `parent_product` int NOT NULL DEFAULT '0',
  `sort_product` int NOT NULL DEFAULT '0',
  `s_product_visible` tinyint NOT NULL DEFAULT '0',
  `s_product` tinyint NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_product`
--

INSERT INTO `ir_product` (`id_product`, `id_user`, `id_type_product`, `parent_product`, `sort_product`, `s_product_visible`, `s_product`) VALUES
(1, 1, 1, 0, 0, 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_product_category`
--

CREATE TABLE `ir_product_category` (
  `id_product_category` int NOT NULL,
  `id_product` int NOT NULL,
  `id_category` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_product_category`
--

INSERT INTO `ir_product_category` (`id_product_category`, `id_product`, `id_category`) VALUES
(1, 1, 3),
(2, 1, 6);

-- --------------------------------------------------------

--
-- Table structure for table `ir_product_lang`
--

CREATE TABLE `ir_product_lang` (
  `id_product_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_product` int NOT NULL,
  `id_tax_rule` int NOT NULL,
  `id_type_of_currency` int NOT NULL,
  `title_product_lang` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtitle_product_lang` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `general_price_product_lang` decimal(19,2) DEFAULT NULL,
  `text_button_general_price_product_lang` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `predominant_color_product_lang` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '#ffffff',
  `background_color_degraded_product_lang` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `general_stock_product_lang` int DEFAULT '0',
  `reference_product_lang` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `friendly_url_product_lang` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `general_link_product_lang` varchar(600) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `text_button_general_link_product_lang` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description_small_product_lang` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `description_large_product_lang` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `special_specifications_product_lang` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `clave_prod_serv_sat_product_lang` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `clave_unidad_sat_product_lang` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `input_product_lang` int DEFAULT '0',
  `output_product_lang` int DEFAULT '0',
  `meta_title_product_lang` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `meta_description_product_lang` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `meta_keywords_product_lang` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `creation_date_product_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update_product_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_product_lang`
--

INSERT INTO `ir_product_lang` (`id_product_lang`, `id_lang`, `id_product`, `id_tax_rule`, `id_type_of_currency`, `title_product_lang`, `subtitle_product_lang`, `general_price_product_lang`, `text_button_general_price_product_lang`, `predominant_color_product_lang`, `background_color_degraded_product_lang`, `general_stock_product_lang`, `reference_product_lang`, `friendly_url_product_lang`, `general_link_product_lang`, `text_button_general_link_product_lang`, `description_small_product_lang`, `description_large_product_lang`, `special_specifications_product_lang`, `clave_prod_serv_sat_product_lang`, `clave_unidad_sat_product_lang`, `input_product_lang`, `output_product_lang`, `meta_title_product_lang`, `meta_description_product_lang`, `meta_keywords_product_lang`, `creation_date_product_lang`, `last_update_product_lang`) VALUES
(1, 1, 1, 3, 1, 'Laptop', 'co2 sfdsfsdf', '2000.00', NULL, '#ffffff', NULL, 0, NULL, 'producto/laptop', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 'Laptop', NULL, NULL, '2025-11-22 02:30:32', '2025-11-22 02:46:42'),
(2, 2, 1, 3, 1, 'Laptop', 'co2 sfdsfsdf', '2000.00', NULL, '#ffffff', NULL, 0, NULL, 'producto/laptop', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 'Laptop', NULL, NULL, '2025-11-22 02:30:32', '2025-11-22 02:46:42');

-- --------------------------------------------------------

--
-- Table structure for table `ir_product_lang_additional_information`
--

CREATE TABLE `ir_product_lang_additional_information` (
  `id_product_lang_additional_information` int NOT NULL,
  `id_type_tag` int NOT NULL,
  `id_product_lang` int NOT NULL,
  `tag_product_lang_additional_information` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `content_product_lang_additional_information` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `hyperlink_product_lang_additional_information` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `parent_product_lang_additional_information` int NOT NULL DEFAULT '0',
  `sort_product_lang_additional_information` int NOT NULL DEFAULT '0',
  `s_visible_product_lang_additional_information` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_product_lang_attribute`
--

CREATE TABLE `ir_product_lang_attribute` (
  `id_product_lang_attribute` int NOT NULL,
  `id_product_lang_presentation` int NOT NULL,
  `id_attribute` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_product_lang_image_lang`
--

CREATE TABLE `ir_product_lang_image_lang` (
  `id_product_lang_image_lang` int NOT NULL,
  `id_product_lang` int NOT NULL,
  `id_image_lang` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_product_lang_image_lang`
--

INSERT INTO `ir_product_lang_image_lang` (`id_product_lang_image_lang`, `id_product_lang`, `id_image_lang`) VALUES
(1, 1, 1),
(2, 2, 2);

-- --------------------------------------------------------

--
-- Table structure for table `ir_product_lang_presentation`
--

CREATE TABLE `ir_product_lang_presentation` (
  `id_product_lang_presentation` int NOT NULL,
  `id_product_lang` int NOT NULL,
  `parent_product_lang_presentation` int DEFAULT '0',
  `sort_product_lang_presentation` int DEFAULT '0',
  `s_product_lang_presentation` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_product_lang_presentation_image_lang`
--

CREATE TABLE `ir_product_lang_presentation_image_lang` (
  `id_product_lang_presentation_image_lang` int NOT NULL,
  `id_product_lang_presentation` int NOT NULL,
  `id_image_lang` int NOT NULL,
  `s_thumbnail_product_lang_presentation_image_lang` tinyint NOT NULL DEFAULT '1',
  `s_main_product_lang_presentation_image_lang` tinyint NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_product_lang_presentation_lang`
--

CREATE TABLE `ir_product_lang_presentation_lang` (
  `id_product_lang_presentation_lang` int NOT NULL,
  `id_product_lang_presentation` int NOT NULL,
  `general_price_product_lang_presentation_lang` decimal(19,2) DEFAULT NULL,
  `general_stock_product_lang_presentation_lang` int DEFAULT NULL,
  `reference_product_lang_presentation_lang` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `meta_title_product_lang_presentation_lang` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `meta_description_product_lang_presentation_lang` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `meta_keywords_product_lang_presentation_lang` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `last_update_product_lang_presentation_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `s_product_lang_presentation_lang_visible` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_product_lang_promotion`
--

CREATE TABLE `ir_product_lang_promotion` (
  `id_product_lang_promotion` int NOT NULL,
  `id_product_lang` int NOT NULL,
  `id_type_promotion` int NOT NULL,
  `title_product_lang_promotion` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `sku_product_lang_promotion` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `price_discount_product_lang_promotion` decimal(19,2) NOT NULL,
  `discount_rate_product_lang_promotion` int NOT NULL,
  `description_small_product_lang_promotion` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `description_large_product_lang_promotion` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `link_product_lang_promotion` varchar(600) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `start_date_product_lang_promotion` date DEFAULT NULL,
  `finish_date_product_lang_promotion` date DEFAULT NULL,
  `total_click_product_lang_promotion` int DEFAULT '0',
  `parent_product_lang_promotion` int NOT NULL DEFAULT '0',
  `sort_product_lang_promotion` int NOT NULL DEFAULT '0',
  `s_product_lang_promotion` tinyint NOT NULL DEFAULT '1',
  `s_visible_product_lang_promotion` tinyint NOT NULL DEFAULT '0',
  `last_update_product_lang_promotion` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_promotion`
--

CREATE TABLE `ir_promotion` (
  `id_promotion` int NOT NULL,
  `start_date_promotion` date DEFAULT NULL,
  `finish_date_promotion` date DEFAULT NULL,
  `total_click_promotion` int DEFAULT '0',
  `parent_promotion` int NOT NULL DEFAULT '0',
  `sort_promotion` int NOT NULL DEFAULT '0',
  `s_promotion` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_promotion_lang`
--

CREATE TABLE `ir_promotion_lang` (
  `id_promotion_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_promotion` int NOT NULL,
  `title_promotion_lang` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `promotional_code_lang` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `description_small_promotion_lang` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `description_large_promotion_lang` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `link_promotion_lang` varchar(600) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `last_update_promotion_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_record`
--

CREATE TABLE `ir_record` (
  `id_record` int NOT NULL,
  `id_user` int NOT NULL,
  `resumen_record` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_record` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_record`
--

INSERT INTO `ir_record` (`id_record`, `id_user`, `resumen_record`, `date_record`) VALUES
(1, 1, 'Inicio sesión paola@iridizen.com', '2025-11-09 03:52:49'),
(2, 1, 'Inicio sesión paola@iridizen.com', '2025-11-22 02:27:12'),
(3, 1, 'Registro el producto Laptop', '2025-11-22 02:30:32'),
(4, 1, 'Registro la imagen Laptop', '2025-11-22 02:45:00'),
(5, 1, 'Registro la categoría Semi-nuevo', '2025-11-22 02:45:30'),
(6, 1, 'Registro la categoría Huawei', '2025-11-22 02:46:20'),
(7, 1, 'Activo Laptop', '2025-11-22 02:46:42'),
(8, 1, 'Registro Slider Tu día deja huella. Haz que valga.', '2025-11-22 02:56:57'),
(9, 1, 'Activo Tu día deja huella. Haz que valga.', '2025-11-22 02:57:03'),
(10, 1, 'Cerro sesión', '2025-11-22 03:46:06'),
(11, 1, 'Inicio sesión paola@iridizen.com', '2025-11-22 19:17:48'),
(12, 1, 'Activo Nayeli Delgado', '2025-11-22 19:18:12'),
(13, 1, 'Cerro sesión', '2025-11-22 19:18:19'),
(16, 1, 'Inicio sesión paola@iridizen.com', '2025-11-22 19:42:28');

-- --------------------------------------------------------

--
-- Table structure for table `ir_regimen_fiscal`
--

CREATE TABLE `ir_regimen_fiscal` (
  `id_regimen_fiscal` int NOT NULL,
  `codigo_regimen_fiscal_lang` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_regimen_fiscal`
--

INSERT INTO `ir_regimen_fiscal` (`id_regimen_fiscal`, `codigo_regimen_fiscal_lang`) VALUES
(1, '605'),
(2, '606'),
(3, '607'),
(4, '608'),
(5, '610'),
(6, '611'),
(7, '612'),
(8, '614'),
(9, '615'),
(10, '616'),
(11, '621'),
(12, '625'),
(13, '626');

-- --------------------------------------------------------

--
-- Table structure for table `ir_regimen_fiscal_lang`
--

CREATE TABLE `ir_regimen_fiscal_lang` (
  `id_regimen_fiscal_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_regimen_fiscal` int NOT NULL,
  `regimen_fiscal_lang` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_regimen_fiscal_lang`
--

INSERT INTO `ir_regimen_fiscal_lang` (`id_regimen_fiscal_lang`, `id_lang`, `id_regimen_fiscal`, `regimen_fiscal_lang`) VALUES
(1, 1, 1, 'Sueldos y Salarios e Ingresos Asimilados a Salario'),
(2, 2, 1, 'Sueldos y Salarios e Ingresos Asimilados a Salario'),
(3, 1, 2, 'Arrendamiento'),
(4, 2, 2, 'Arrendamiento'),
(5, 1, 3, 'Régimen de Enajenación o Adquisición de Bienes'),
(6, 2, 3, 'Régimen de Enajenación o Adquisición de Bienes'),
(7, 1, 4, 'Demás ingresos'),
(8, 2, 4, 'Demás ingresos'),
(9, 1, 5, 'Residentes en el Extranjero sin Establecimiento Permanente en México'),
(10, 2, 5, 'Residentes en el Extranjero sin Establecimiento Permanente en México'),
(11, 1, 6, 'Ingresos por Dividendos (socios y accionistas)'),
(12, 2, 6, 'Ingresos por Dividendos (socios y accionistas)'),
(13, 1, 7, 'Personas Físicas con Actividades Empresariales y Profesionales'),
(14, 2, 7, 'Personas Físicas con Actividades Empresariales y Profesionales'),
(15, 1, 8, 'Ingresos por intereses'),
(16, 2, 8, 'Ingresos por intereses'),
(17, 1, 9, 'Régimen de los ingresos por obtención de premios'),
(18, 2, 9, 'Régimen de los ingresos por obtención de premios'),
(19, 1, 10, 'Sin obligaciones fiscales'),
(20, 2, 10, 'Sin obligaciones fiscales'),
(21, 1, 11, 'Incorporación Fiscal'),
(22, 2, 11, 'Incorporación Fiscal'),
(23, 1, 12, 'Régimen de las Actividades Empresariales con ingresos a través de Plataformas Tecnológicas'),
(24, 2, 12, 'Régimen de las Actividades Empresariales con ingresos a través de Plataformas Tecnológicas'),
(25, 1, 13, 'Régimen Simplificado de Confianza'),
(26, 2, 13, 'Régimen Simplificado de Confianza');

-- --------------------------------------------------------

--
-- Table structure for table `ir_role`
--

CREATE TABLE `ir_role` (
  `id_role` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_role`
--

INSERT INTO `ir_role` (`id_role`) VALUES
(1),
(2),
(3),
(4);

-- --------------------------------------------------------

--
-- Table structure for table `ir_role_lang`
--

CREATE TABLE `ir_role_lang` (
  `id_role_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_role` int NOT NULL,
  `name_role` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_role_lang`
--

INSERT INTO `ir_role_lang` (`id_role_lang`, `id_lang`, `id_role`, `name_role`) VALUES
(1, 1, 1, 'Súper Administrador'),
(2, 2, 1, 'Super Administrator'),
(3, 1, 2, 'Administrador'),
(4, 2, 2, 'Administrator'),
(5, 1, 3, 'Usuario'),
(6, 2, 3, 'User'),
(7, 1, 4, 'Vendedor(a)'),
(8, 2, 4, 'Vendedor(a)');

-- --------------------------------------------------------

--
-- Table structure for table `ir_session_attempt`
--

CREATE TABLE `ir_session_attempt` (
  `id_session_attempt` int NOT NULL,
  `id_user` int NOT NULL,
  `time_session_attempt` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_slider`
--

CREATE TABLE `ir_slider` (
  `id_slider` int NOT NULL,
  `id_image_lang` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_slider`
--

INSERT INTO `ir_slider` (`id_slider`, `id_image_lang`) VALUES
(1, 3),
(2, 4);

-- --------------------------------------------------------

--
-- Table structure for table `ir_slider_image_lang`
--

CREATE TABLE `ir_slider_image_lang` (
  `id_slider_image_lang` int NOT NULL,
  `id_slider` int NOT NULL,
  `id_image_lang` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_social_media`
--

CREATE TABLE `ir_social_media` (
  `id_social_media` int NOT NULL,
  `name_social_media` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `photo_social_media` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `icon_social_media` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `parent_social_media` int NOT NULL DEFAULT '0',
  `sort_social_media` int NOT NULL DEFAULT '0',
  `s_social_media` tinyint NOT NULL DEFAULT '1',
  `last_social_media` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_social_media`
--

INSERT INTO `ir_social_media` (`id_social_media`, `name_social_media`, `photo_social_media`, `icon_social_media`, `parent_social_media`, `sort_social_media`, `s_social_media`, `last_social_media`) VALUES
(1, 'Young Living', 'ico-young-iving', 'fas fa-heartbeat', 0, 0, 1, '2025-11-09 03:30:37'),
(2, 'Facebook', 'ico-facebook', 'fab fa-facebook-f', 0, 0, 1, '2025-11-09 03:30:37'),
(3, 'X', 'ico-twitter', 'fab fa-twitter', 0, 0, 1, '2025-11-09 03:30:37'),
(4, 'Pinterest', 'ico-pinterest', 'fab fa-pinterest-p', 0, 0, 1, '2025-11-09 03:30:37'),
(5, 'Instagram', 'ico-instagram', 'fab fa-instagram', 0, 0, 1, '2025-11-09 03:30:37'),
(6, 'Sharethis', 'ico-sharethis', '', 0, 0, 1, '2025-11-09 03:30:37'),
(7, 'Linkedin', 'ico-linkedin', 'fab fa-linkedin-in', 0, 0, 1, '2025-11-09 03:30:37'),
(8, 'Messenger', 'ico-messenger', 'fab fa-facebook-messenger', 0, 0, 1, '2025-11-09 03:30:37'),
(9, 'Reddit', 'ico-reddit', 'fab fa-reddit-alien', 0, 0, 1, '2025-11-09 03:30:37'),
(10, 'Tumblr', 'ico-tumblr', 'fab fa-tumblr', 0, 0, 1, '2025-11-09 03:30:37'),
(11, 'Digg', 'ico-digg', 'fab fa-digg', 0, 0, 1, '2025-11-09 03:30:37'),
(12, 'Google Plus', 'ico-google_plus', 'fab fa-google-plus-g', 0, 0, 1, '2025-11-09 03:30:37'),
(13, 'Whatsapp', 'ico-whatsapp', 'fab fa-whatsapp', 0, 0, 1, '2025-11-09 03:30:37'),
(14, 'Vk', 'ico-vk', 'fab fa-vk', 0, 0, 1, '2025-11-09 03:30:37'),
(15, 'Weibo', 'ico-weibo', 'fab fa-weibo', 0, 0, 1, '2025-11-09 03:30:37'),
(16, 'Odnoklassniki', 'ico-odnoklassniki', 'fab fa-odnoklassniki', 0, 0, 1, '2025-11-09 03:30:37'),
(17, 'Xing', 'ico-xing', 'fab fa-xing', 0, 0, 1, '2025-11-09 03:30:37'),
(18, 'Blogger', 'ico-blogger', 'fab fa-blogger-b', 0, 0, 1, '2025-11-09 03:30:37'),
(19, 'Meneame', 'ico-meneame', '', 0, 0, 1, '2025-11-09 03:30:37'),
(20, 'Mailru', 'ico-mailru', '', 0, 0, 1, '2025-11-09 03:30:37'),
(21, 'Delicious', 'ico-delicious', 'fab fa-delicious', 0, 0, 1, '2025-11-09 03:30:37'),
(22, 'Livejournal', 'ico-livejournal', '', 0, 0, 1, '2025-11-09 03:30:37'),
(23, 'Wechat', 'ico-wechat', 'fab fa-weixin', 0, 0, 1, '2025-11-09 03:30:37');

-- --------------------------------------------------------

--
-- Table structure for table `ir_tax_rule`
--

CREATE TABLE `ir_tax_rule` (
  `id_tax_rule` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_tax_rule`
--

INSERT INTO `ir_tax_rule` (`id_tax_rule`) VALUES
(1),
(2),
(3);

-- --------------------------------------------------------

--
-- Table structure for table `ir_tax_rule_lang`
--

CREATE TABLE `ir_tax_rule_lang` (
  `id_tax_rule_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_tax_rule` int NOT NULL,
  `title_tax_rule_lang` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `value_tax_rule_lang` int DEFAULT NULL,
  `last_tax_rule_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_tax_rule_lang`
--

INSERT INTO `ir_tax_rule_lang` (`id_tax_rule_lang`, `id_lang`, `id_tax_rule`, `title_tax_rule_lang`, `value_tax_rule_lang`, `last_tax_rule_lang`) VALUES
(1, 1, 1, 'Sin impuestos', 0, '2025-11-09 03:30:38'),
(2, 2, 1, 'Without taxation', 0, '2025-11-09 03:30:38'),
(3, 1, 2, 'Tasa Reducida MX (11%)', 11, '2025-11-09 03:30:38'),
(4, 2, 2, 'MX Reduced Rate (11%)', 11, '2025-11-09 03:30:38'),
(5, 1, 3, 'Tasa estándar MX (16%)', 16, '2025-11-09 03:30:38'),
(6, 2, 3, 'MX Standard Rate (16%)', 16, '2025-11-09 03:30:38');

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_customize`
--

CREATE TABLE `ir_type_customize` (
  `id_type_customize` int NOT NULL,
  `parent_type_customize` int NOT NULL DEFAULT '0',
  `sort_type_customize` int NOT NULL DEFAULT '0',
  `default_type_route_customize` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `s_type_customize` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_customize`
--

INSERT INTO `ir_type_customize` (`id_type_customize`, `parent_type_customize`, `sort_type_customize`, `default_type_route_customize`, `s_type_customize`) VALUES
(1, 0, 0, 'img/personalizaciones/fondos', 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_customize_lang`
--

CREATE TABLE `ir_type_customize_lang` (
  `id_type_customize_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_type_customize` int NOT NULL,
  `name_type_customize_lang` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_customize_lang`
--

INSERT INTO `ir_type_customize_lang` (`id_type_customize_lang`, `id_lang`, `id_type_customize`, `name_type_customize_lang`) VALUES
(1, 1, 1, 'Fondos imagen'),
(2, 2, 1, 'Backgrounds image');

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_image`
--

CREATE TABLE `ir_type_image` (
  `id_type_image` int NOT NULL,
  `parent_type_image` int NOT NULL DEFAULT '0',
  `sort_type_image` int NOT NULL DEFAULT '0',
  `default_route_type_image` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `s_type_image` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_image`
--

INSERT INTO `ir_type_image` (`id_type_image`, `parent_type_image`, `sort_type_image`, `default_route_type_image`, `s_type_image`) VALUES
(1, 0, 0, 'img/usuarios', 1),
(2, 0, 0, 'img/perfiles', 1),
(3, 0, 0, 'img/permisos', 1),
(4, 0, 0, 'img/mi_perfil', 1),
(5, 0, 0, 'img/redes_sociales', 1),
(6, 0, 0, 'img/sliders', 1),
(7, 0, 0, 'img/summernote', 1),
(8, 0, 0, 'img/archivos_adjuntos', 1),
(9, 0, 0, 'img/testimoniales', 1),
(10, 0, 0, 'img/categorias', 1),
(11, 0, 0, 'img/subcategorias', 1),
(12, 0, 0, 'img/pagina_web', 1),
(13, 0, 0, 'img/menus', 1),
(14, 0, 0, 'img/galerias', 1),
(15, 0, 0, 'img/productos', 1),
(16, 0, 0, 'img/recetas', 1),
(17, 0, 0, 'img/distribuidores', 1),
(18, 0, 0, 'img/eventos', 1),
(19, 0, 0, 'img/patrocinadores', 1),
(20, 0, 0, 'img/blogs', 1),
(21, 0, 0, 'img/carrusel', 1),
(22, 0, 0, 'img/mapa', 1),
(23, 0, 0, 'img/atributos', 1),
(24, 0, 0, 'img/promociones', 1),
(25, 0, 0, 'img/formularios', 1),
(26, 0, 0, 'img/carrito_de_compra', 1),
(27, 0, 0, 'img/chat', 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_image_lang`
--

CREATE TABLE `ir_type_image_lang` (
  `id_type_image_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_type_image` int NOT NULL,
  `type_image_lang` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_update_type_image_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_image_lang`
--

INSERT INTO `ir_type_image_lang` (`id_type_image_lang`, `id_lang`, `id_type_image`, `type_image_lang`, `last_update_type_image_lang`) VALUES
(1, 1, 1, 'Usuarios', '2025-11-09 03:30:38'),
(2, 2, 1, 'Users', '2025-11-09 03:30:38'),
(3, 1, 2, 'Perfiles', '2025-11-09 03:30:38'),
(4, 2, 2, 'Profiles', '2025-11-09 03:30:38'),
(5, 1, 3, 'Permisos', '2025-11-09 03:30:38'),
(6, 2, 3, 'Permissions', '2025-11-09 03:30:38'),
(7, 1, 4, 'Mi perfil', '2025-11-09 03:30:38'),
(8, 2, 4, 'My profile', '2025-11-09 03:30:38'),
(9, 1, 5, 'Redes sociales', '2025-11-09 03:30:38'),
(10, 2, 5, 'Social networks', '2025-11-09 03:30:38'),
(11, 1, 6, 'Sliders', '2025-11-09 03:30:38'),
(12, 2, 6, 'Sliders', '2025-11-09 03:30:38'),
(13, 1, 7, 'Summernote', '2025-11-09 03:30:38'),
(14, 2, 7, 'Summernote', '2025-11-09 03:30:38'),
(15, 1, 8, 'Archivos adjuntos', '2025-11-09 03:30:38'),
(16, 2, 8, 'Attached files', '2025-11-09 03:30:38'),
(17, 1, 9, 'Testimoniales', '2025-11-09 03:30:38'),
(18, 2, 9, 'Testimonials', '2025-11-09 03:30:38'),
(19, 1, 10, 'Categorías', '2025-11-09 03:30:38'),
(20, 2, 10, 'Categories', '2025-11-09 03:30:38'),
(21, 1, 11, 'Subcategorías', '2025-11-09 03:30:38'),
(22, 2, 11, 'Subcategories', '2025-11-09 03:30:38'),
(23, 1, 12, 'Página web', '2025-11-09 03:30:38'),
(24, 2, 12, 'Website', '2025-11-09 03:30:38'),
(25, 1, 13, 'Menús', '2025-11-09 03:30:38'),
(26, 2, 13, 'Menus', '2025-11-09 03:30:38'),
(27, 1, 14, 'Galerías', '2025-11-09 03:30:38'),
(28, 2, 14, 'Galleries', '2025-11-09 03:30:38'),
(29, 1, 15, 'Productos', '2025-11-09 03:30:38'),
(30, 2, 15, 'Products', '2025-11-09 03:30:38'),
(31, 1, 16, 'Recetas', '2025-11-09 03:30:38'),
(32, 2, 16, 'Recipes', '2025-11-09 03:30:38'),
(33, 1, 17, 'Distribuidores', '2025-11-09 03:30:38'),
(34, 2, 17, 'Dealers', '2025-11-09 03:30:38'),
(35, 1, 18, 'Eventos', '2025-11-09 03:30:38'),
(36, 2, 18, 'Events', '2025-11-09 03:30:38'),
(37, 1, 19, 'Patrocinadores', '2025-11-09 03:30:38'),
(38, 2, 19, 'Sponsors', '2025-11-09 03:30:38'),
(39, 1, 20, 'Blogs', '2025-11-09 03:30:38'),
(40, 2, 20, 'Blogs', '2025-11-09 03:30:38'),
(41, 1, 21, 'Carrusel', '2025-11-09 03:30:38'),
(42, 2, 21, 'Carousel', '2025-11-09 03:30:38'),
(43, 1, 22, 'Mapa', '2025-11-09 03:30:38'),
(44, 2, 22, 'Map', '2025-11-09 03:30:38'),
(45, 1, 23, 'Atributos', '2025-11-09 03:30:38'),
(46, 2, 23, 'Attributes', '2025-11-09 03:30:38'),
(47, 1, 24, 'Promociones', '2025-11-09 03:30:38'),
(48, 2, 24, 'Promotion', '2025-11-09 03:30:38'),
(49, 1, 25, 'Formularios', '2025-11-09 03:30:38'),
(50, 2, 25, 'Forms', '2025-11-09 03:30:38'),
(51, 1, 26, 'Carrito de compra', '2025-11-09 03:30:38'),
(52, 2, 26, 'Shopping cart', '2025-11-09 03:30:38'),
(53, 1, 27, 'Chat', '2025-11-09 03:30:38'),
(54, 2, 27, 'Chat', '2025-11-09 03:30:38');

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_of_currency`
--

CREATE TABLE `ir_type_of_currency` (
  `id_type_of_currency` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_of_currency`
--

INSERT INTO `ir_type_of_currency` (`id_type_of_currency`) VALUES
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(8),
(9),
(10),
(11),
(12);

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_of_currency_lang`
--

CREATE TABLE `ir_type_of_currency_lang` (
  `id_type_of_currency_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_type_of_currency` int NOT NULL,
  `type_of_currency_lang` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `value_type_of_currency_lang` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `symbol_type_of_currency_lang` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_type_of_currency_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_of_currency_lang`
--

INSERT INTO `ir_type_of_currency_lang` (`id_type_of_currency_lang`, `id_lang`, `id_type_of_currency`, `type_of_currency_lang`, `value_type_of_currency_lang`, `symbol_type_of_currency_lang`, `last_type_of_currency_lang`) VALUES
(1, 1, 1, 'Peso mexicano', 'MXN', '$', '2025-11-09 03:30:38'),
(2, 2, 1, 'Peso mexicano', 'MXN', '$', '2025-11-09 03:30:38'),
(3, 1, 2, 'American dollar', 'USD', '', '2025-11-09 03:30:38'),
(4, 2, 2, 'MX', 'USD', '', '2025-11-09 03:30:38'),
(5, 1, 3, 'Euro ', 'EUR', '€', '2025-11-09 03:30:38'),
(6, 2, 3, 'Euro', 'EUR', '€', '2025-11-09 03:30:38'),
(7, 1, 4, 'Libra esterlina', 'GBP', '', '2025-11-09 03:30:38'),
(8, 2, 4, 'Libra esterlina', 'GBP', '', '2025-11-09 03:30:38'),
(9, 1, 5, 'Franco suizo', 'CHF', '', '2025-11-09 03:30:38'),
(10, 2, 5, 'Franco suizo', 'CHF', '', '2025-11-09 03:30:38'),
(11, 1, 6, 'Yen japonés', 'JPY', '', '2025-11-09 03:30:38'),
(12, 2, 6, 'Yen japonés', 'JPY', '', '2025-11-09 03:30:38'),
(13, 1, 7, 'Dólar hongkonés', 'HKD', '', '2025-11-09 03:30:38'),
(14, 2, 7, 'Dólar hongkonés', 'HKD', '', '2025-11-09 03:30:38'),
(15, 1, 8, 'Dólar canadiense', 'CAD', '', '2025-11-09 03:30:38'),
(16, 2, 8, 'Dólar canadiense', 'CAD', '', '2025-11-09 03:30:38'),
(17, 1, 9, 'Yuan chino', 'CNY', '', '2025-11-09 03:30:38'),
(18, 2, 9, 'Yuan chino', 'CNY', '', '2025-11-09 03:30:38'),
(19, 1, 10, 'Dólar australiano', 'AUD', '', '2025-11-09 03:30:38'),
(20, 2, 10, 'Dólar australiano', 'AUD', '', '2025-11-09 03:30:38'),
(21, 1, 11, 'Real brasileño', 'BRL', '', '2025-11-09 03:30:38'),
(22, 2, 11, 'Real brasileño', 'BRL', '', '2025-11-09 03:30:38'),
(23, 1, 12, 'Rublo ruso', 'RUB', '', '2025-11-09 03:30:38'),
(24, 2, 12, 'Rublo ruso', 'RUB', '', '2025-11-09 03:30:38');

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_product`
--

CREATE TABLE `ir_type_product` (
  `id_type_product` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_product`
--

INSERT INTO `ir_type_product` (`id_type_product`) VALUES
(1),
(2);

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_product_lang`
--

CREATE TABLE `ir_type_product_lang` (
  `id_type_product_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_type_product` int NOT NULL,
  `title_type_product_lang` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `badge_type_product_lang` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_product_lang`
--

INSERT INTO `ir_type_product_lang` (`id_type_product_lang`, `id_lang`, `id_type_product`, `title_type_product_lang`, `badge_type_product_lang`) VALUES
(1, 1, 1, 'Producto', 'dark'),
(2, 2, 1, 'Product', 'dark'),
(3, 1, 2, 'Accesorio', 'info'),
(4, 2, 2, 'Accessory', 'info');

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_promotion`
--

CREATE TABLE `ir_type_promotion` (
  `id_type_promotion` int NOT NULL,
  `parent_type_promotion` int NOT NULL DEFAULT '0',
  `sort_type_promotion` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_promotion`
--

INSERT INTO `ir_type_promotion` (`id_type_promotion`, `parent_type_promotion`, `sort_type_promotion`) VALUES
(1, 0, 0),
(2, 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_promotion_lang`
--

CREATE TABLE `ir_type_promotion_lang` (
  `id_type_promotion_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_type_promotion` int NOT NULL,
  `type_promotion_lang` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `last_update_type_promotion_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_promotion_lang`
--

INSERT INTO `ir_type_promotion_lang` (`id_type_promotion_lang`, `id_lang`, `id_type_promotion`, `type_promotion_lang`, `last_update_type_promotion_lang`) VALUES
(1, 1, 1, 'Importe', '2025-11-09 03:30:39'),
(2, 2, 1, 'Amount', '2025-11-09 03:30:39'),
(3, 1, 2, 'Porcentaje', '2025-11-09 03:30:39'),
(4, 2, 2, 'Percentage', '2025-11-09 03:30:39');

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_tag`
--

CREATE TABLE `ir_type_tag` (
  `id_type_tag` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_tag`
--

INSERT INTO `ir_type_tag` (`id_type_tag`) VALUES
(1),
(2),
(3),
(4),
(5);

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_tag_lang`
--

CREATE TABLE `ir_type_tag_lang` (
  `id_type_tag_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_type_tag` int NOT NULL,
  `title_type_tag_lang` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `badge_type_tag_lang` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_tag_lang`
--

INSERT INTO `ir_type_tag_lang` (`id_type_tag_lang`, `id_lang`, `id_type_tag`, `title_type_tag_lang`, `badge_type_tag_lang`) VALUES
(1, 1, 1, 'Texto', 'dark'),
(2, 2, 1, 'Text', 'dark'),
(3, 1, 2, 'Link', 'info'),
(4, 2, 2, 'Link', 'info'),
(5, 1, 3, 'Correo', 'success'),
(6, 2, 3, 'Email', 'success'),
(7, 1, 4, 'Celular', 'secondary'),
(8, 2, 4, 'Cellphone', 'secondary'),
(9, 1, 5, 'Huella de carbono', 'primary'),
(10, 2, 5, 'Carbon footprint', 'primary');

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_version`
--

CREATE TABLE `ir_type_version` (
  `id_type_version` int NOT NULL,
  `parent_type_version` int NOT NULL DEFAULT '0',
  `sort_type_version` int NOT NULL DEFAULT '0',
  `s_type_version` tinyint NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_version`
--

INSERT INTO `ir_type_version` (`id_type_version`, `parent_type_version`, `sort_type_version`, `s_type_version`) VALUES
(1, 0, 0, 1),
(2, 0, 0, 1),
(3, 0, 0, 1),
(4, 0, 0, 1),
(5, 0, 0, 1),
(6, 0, 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `ir_type_version_lang`
--

CREATE TABLE `ir_type_version_lang` (
  `id_type_version_lang` int NOT NULL,
  `id_lang` int NOT NULL,
  `id_type_version` int NOT NULL,
  `type_version_lang` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_update_type_version_lang` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_type_version_lang`
--

INSERT INTO `ir_type_version_lang` (`id_type_version_lang`, `id_lang`, `id_type_version`, `type_version_lang`, `last_update_type_version_lang`) VALUES
(1, 1, 1, 'Dispositivos XX-Large (escritorios más grandes, 1400 px y más)', '2025-11-09 03:30:38'),
(2, 2, 1, 'XX-Large devices (larger desktops, 1400px and up)', '2025-11-09 03:30:38'),
(3, 1, 2, 'Dispositivos X-Large (equipos de escritorio grandes, 1200 px y más)', '2025-11-09 03:30:38'),
(4, 2, 2, 'X-Large devices (large desktops, 1200px and up)', '2025-11-09 03:30:38'),
(5, 1, 3, 'Dispositivos grandes (computadoras de escritorio, 992 px y más)', '2025-11-09 03:30:38'),
(6, 2, 3, 'Large devices (desktops, 992px and up)', '2025-11-09 03:30:38'),
(7, 1, 4, 'Dispositivos medianos (tabletas, 768 px y más)', '2025-11-09 03:30:38'),
(8, 2, 4, 'Medium devices (tablets, 768px and up)', '2025-11-09 03:30:38'),
(9, 1, 5, 'Dispositivos pequeños (teléfonos horizontales, 576 px y más)', '2025-11-09 03:30:38'),
(10, 2, 5, 'Small devices (landscape phones, 576px and up)', '2025-11-09 03:30:38'),
(11, 1, 6, 'Dispositivos X-Small (teléfonos verticales, menos de 576 px)', '2025-11-09 03:30:38'),
(12, 2, 6, 'X-Small devices (portrait phones, less than 576px)', '2025-11-09 03:30:38');

-- --------------------------------------------------------

--
-- Table structure for table `ir_user`
--

CREATE TABLE `ir_user` (
  `id_user` int NOT NULL,
  `id_role` int NOT NULL,
  `name_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `rfc_user` varchar(13) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `curp_user` varchar(18) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `membership_number_user` varchar(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `about_me_user` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `biography_user` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `birthdate_user` date DEFAULT NULL,
  `age_user` int DEFAULT NULL,
  `gender_user` varchar(5) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `lada_telephone_user` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `telephone_user` varchar(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lada_cell_phone_user` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cell_phone_user` varchar(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `ship_address_user` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_user` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country_user` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_user` varchar(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city_user` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `municipality_user` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `colony_user` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cp_user` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `street_user` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `outdoor_number_user` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `interior_number_user` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `between_street1_user` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `between_street2_user` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `other_references_user` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nationality_user` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `filters_user` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `profile_photo_user` varchar(70) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `username_website` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_user` char(128) COLLATE utf8mb4_bin NOT NULL,
  `salt_user` char(128) COLLATE utf8mb4_bin NOT NULL,
  `interbank_code_user` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `parent_user` int NOT NULL DEFAULT '0',
  `sort_user` int NOT NULL DEFAULT '0',
  `s_user` tinyint NOT NULL DEFAULT '0',
  `registration_date_user` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_session_user` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_user`
--

INSERT INTO `ir_user` (`id_user`, `id_role`, `name_user`, `last_name_user`, `rfc_user`, `curp_user`, `membership_number_user`, `about_me_user`, `biography_user`, `birthdate_user`, `age_user`, `gender_user`, `lada_telephone_user`, `telephone_user`, `lada_cell_phone_user`, `cell_phone_user`, `email_user`, `ship_address_user`, `address_user`, `country_user`, `state_user`, `city_user`, `municipality_user`, `colony_user`, `cp_user`, `street_user`, `outdoor_number_user`, `interior_number_user`, `between_street1_user`, `between_street2_user`, `other_references_user`, `nationality_user`, `filters_user`, `profile_photo_user`, `username_website`, `password_user`, `salt_user`, `interbank_code_user`, `parent_user`, `sort_user`, `s_user`, `registration_date_user`, `last_session_user`) VALUES
(1, 1, 'Paola Nayeli Angelica', 'Gonzaléz Delgado', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'F', NULL, NULL, NULL, NULL, 'paola@iridizen.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'profile.png', NULL, '0baae7000a8f57ed7a47f0536bb02e7c9b64de51349028758791560b1ac6a25485870cc9dd79fcdfb04f0902ca714ee94829561d8b6b298be05c38b26e5f7221', '147002ef8e3c87afd1969dff0ecafdfed3ac42497e922974ae7cd710c4e0cfaa9418a90bae5e9af0a31fb2ff595311fc619a99bfc4268205347a7c46a65dc5ec', NULL, 0, 0, 1, '2025-11-08 21:30:38', '2025-11-22 13:42:28');

-- --------------------------------------------------------

--
-- Table structure for table `ir_user_customize`
--

CREATE TABLE `ir_user_customize` (
  `id_user_customize` int NOT NULL,
  `id_customize` int NOT NULL,
  `id_user` int NOT NULL,
  `last_user_customize` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Dumping data for table `ir_user_customize`
--

INSERT INTO `ir_user_customize` (`id_user_customize`, `id_customize`, `id_user`, `last_user_customize`) VALUES
(1, 1, 1, '2025-11-08 21:30:38');

-- --------------------------------------------------------

--
-- Table structure for table `ir_user_gallery_image_lang`
--

CREATE TABLE `ir_user_gallery_image_lang` (
  `id_user_gallery_image_lang` int NOT NULL,
  `id_user` int NOT NULL,
  `id_image_lang` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `ir_user_social_media`
--

CREATE TABLE `ir_user_social_media` (
  `id_user_social_media` int NOT NULL,
  `id_social_media` int NOT NULL,
  `id_user` int NOT NULL,
  `url_user_social_media` varchar(600) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `s_user_social_media` tinyint NOT NULL DEFAULT '1',
  `last_user_social_media` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ir_api_factura`
--
ALTER TABLE `ir_api_factura`
  ADD PRIMARY KEY (`ir_api_factura`);

--
-- Indexes for table `ir_attribute`
--
ALTER TABLE `ir_attribute`
  ADD PRIMARY KEY (`id_attribute`),
  ADD KEY `id_user` (`id_user`);

--
-- Indexes for table `ir_attribute_lang`
--
ALTER TABLE `ir_attribute_lang`
  ADD PRIMARY KEY (`id_attribute_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_attribute` (`id_attribute`);

--
-- Indexes for table `ir_category`
--
ALTER TABLE `ir_category`
  ADD PRIMARY KEY (`id_category`),
  ADD KEY `id_user` (`id_user`);

--
-- Indexes for table `ir_category_lang`
--
ALTER TABLE `ir_category_lang`
  ADD PRIMARY KEY (`id_category_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_category` (`id_category`);
ALTER TABLE `ir_category_lang` ADD FULLTEXT KEY `title_category_lang` (`title_category_lang`,`subtitle_category_lang`,`description_small_category_lang`);

--
-- Indexes for table `ir_category_lang_image_lang`
--
ALTER TABLE `ir_category_lang_image_lang`
  ADD PRIMARY KEY (`id_category_lang_image_lang`),
  ADD KEY `id_category_lang` (`id_category_lang`),
  ADD KEY `id_image_section_lang` (`id_image_section_lang`),
  ADD KEY `id_image_lang` (`id_image_lang`);

--
-- Indexes for table `ir_customize`
--
ALTER TABLE `ir_customize`
  ADD PRIMARY KEY (`id_customize`),
  ADD KEY `id_type_customize` (`id_type_customize`);

--
-- Indexes for table `ir_customize_lang`
--
ALTER TABLE `ir_customize_lang`
  ADD PRIMARY KEY (`id_customize_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_customize` (`id_customize`);

--
-- Indexes for table `ir_file`
--
ALTER TABLE `ir_file`
  ADD PRIMARY KEY (`id_file`);

--
-- Indexes for table `ir_file_lang`
--
ALTER TABLE `ir_file_lang`
  ADD PRIMARY KEY (`id_file_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_file` (`id_file`);
ALTER TABLE `ir_file_lang` ADD FULLTEXT KEY `title_file_lang` (`title_file_lang`);

--
-- Indexes for table `ir_image`
--
ALTER TABLE `ir_image`
  ADD PRIMARY KEY (`id_image`),
  ADD KEY `id_type_image` (`id_type_image`);

--
-- Indexes for table `ir_image_lang`
--
ALTER TABLE `ir_image_lang`
  ADD PRIMARY KEY (`id_image_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_image` (`id_image`);

--
-- Indexes for table `ir_image_lang_version`
--
ALTER TABLE `ir_image_lang_version`
  ADD PRIMARY KEY (`id_image_lang_version`),
  ADD KEY `id_image_lang` (`id_image_lang`),
  ADD KEY `id_type_version` (`id_type_version`);

--
-- Indexes for table `ir_image_section`
--
ALTER TABLE `ir_image_section`
  ADD PRIMARY KEY (`id_image_section`);

--
-- Indexes for table `ir_image_section_lang`
--
ALTER TABLE `ir_image_section_lang`
  ADD PRIMARY KEY (`id_image_section_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_image_section` (`id_image_section`);

--
-- Indexes for table `ir_lang`
--
ALTER TABLE `ir_lang`
  ADD PRIMARY KEY (`id_lang`);

--
-- Indexes for table `ir_menu`
--
ALTER TABLE `ir_menu`
  ADD PRIMARY KEY (`id_menu`);

--
-- Indexes for table `ir_menu_image`
--
ALTER TABLE `ir_menu_image`
  ADD PRIMARY KEY (`id_menu_image`),
  ADD KEY `id_menu` (`id_menu`),
  ADD KEY `id_image` (`id_image`);

--
-- Indexes for table `ir_menu_lang`
--
ALTER TABLE `ir_menu_lang`
  ADD PRIMARY KEY (`id_menu_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_menu` (`id_menu`);

--
-- Indexes for table `ir_product`
--
ALTER TABLE `ir_product`
  ADD PRIMARY KEY (`id_product`),
  ADD KEY `id_type_product` (`id_type_product`);

--
-- Indexes for table `ir_product_category`
--
ALTER TABLE `ir_product_category`
  ADD PRIMARY KEY (`id_product_category`),
  ADD KEY `id_product` (`id_product`),
  ADD KEY `id_category` (`id_category`);

--
-- Indexes for table `ir_product_lang`
--
ALTER TABLE `ir_product_lang`
  ADD PRIMARY KEY (`id_product_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_product` (`id_product`),
  ADD KEY `id_tax_rule` (`id_tax_rule`),
  ADD KEY `id_type_of_currency` (`id_type_of_currency`);
ALTER TABLE `ir_product_lang` ADD FULLTEXT KEY `title_product_lang` (`title_product_lang`,`subtitle_product_lang`,`reference_product_lang`,`description_small_product_lang`,`meta_title_product_lang`,`meta_description_product_lang`,`meta_keywords_product_lang`);

--
-- Indexes for table `ir_product_lang_additional_information`
--
ALTER TABLE `ir_product_lang_additional_information`
  ADD PRIMARY KEY (`id_product_lang_additional_information`),
  ADD KEY `id_type_tag` (`id_type_tag`),
  ADD KEY `id_product_lang` (`id_product_lang`);

--
-- Indexes for table `ir_product_lang_attribute`
--
ALTER TABLE `ir_product_lang_attribute`
  ADD PRIMARY KEY (`id_product_lang_attribute`),
  ADD KEY `id_product_lang_presentation` (`id_product_lang_presentation`),
  ADD KEY `id_attribute` (`id_attribute`);

--
-- Indexes for table `ir_product_lang_image_lang`
--
ALTER TABLE `ir_product_lang_image_lang`
  ADD PRIMARY KEY (`id_product_lang_image_lang`),
  ADD KEY `id_product_lang` (`id_product_lang`),
  ADD KEY `id_image_lang` (`id_image_lang`);

--
-- Indexes for table `ir_product_lang_presentation`
--
ALTER TABLE `ir_product_lang_presentation`
  ADD PRIMARY KEY (`id_product_lang_presentation`),
  ADD KEY `id_product_lang` (`id_product_lang`);

--
-- Indexes for table `ir_product_lang_presentation_image_lang`
--
ALTER TABLE `ir_product_lang_presentation_image_lang`
  ADD PRIMARY KEY (`id_product_lang_presentation_image_lang`),
  ADD KEY `id_product_lang_presentation` (`id_product_lang_presentation`),
  ADD KEY `id_image_lang` (`id_image_lang`);

--
-- Indexes for table `ir_product_lang_presentation_lang`
--
ALTER TABLE `ir_product_lang_presentation_lang`
  ADD PRIMARY KEY (`id_product_lang_presentation_lang`),
  ADD KEY `id_product_lang_presentation` (`id_product_lang_presentation`);

--
-- Indexes for table `ir_product_lang_promotion`
--
ALTER TABLE `ir_product_lang_promotion`
  ADD PRIMARY KEY (`id_product_lang_promotion`),
  ADD KEY `id_product_lang` (`id_product_lang`),
  ADD KEY `id_type_promotion` (`id_type_promotion`);

--
-- Indexes for table `ir_promotion`
--
ALTER TABLE `ir_promotion`
  ADD PRIMARY KEY (`id_promotion`);

--
-- Indexes for table `ir_promotion_lang`
--
ALTER TABLE `ir_promotion_lang`
  ADD PRIMARY KEY (`id_promotion_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_promotion` (`id_promotion`);

--
-- Indexes for table `ir_record`
--
ALTER TABLE `ir_record`
  ADD PRIMARY KEY (`id_record`),
  ADD KEY `id_user` (`id_user`);

--
-- Indexes for table `ir_regimen_fiscal`
--
ALTER TABLE `ir_regimen_fiscal`
  ADD PRIMARY KEY (`id_regimen_fiscal`);

--
-- Indexes for table `ir_regimen_fiscal_lang`
--
ALTER TABLE `ir_regimen_fiscal_lang`
  ADD PRIMARY KEY (`id_regimen_fiscal_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_regimen_fiscal` (`id_regimen_fiscal`);

--
-- Indexes for table `ir_role`
--
ALTER TABLE `ir_role`
  ADD PRIMARY KEY (`id_role`);

--
-- Indexes for table `ir_role_lang`
--
ALTER TABLE `ir_role_lang`
  ADD PRIMARY KEY (`id_role_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_role` (`id_role`);

--
-- Indexes for table `ir_session_attempt`
--
ALTER TABLE `ir_session_attempt`
  ADD PRIMARY KEY (`id_session_attempt`),
  ADD KEY `id_user` (`id_user`);

--
-- Indexes for table `ir_slider`
--
ALTER TABLE `ir_slider`
  ADD PRIMARY KEY (`id_slider`),
  ADD KEY `id_image_lang` (`id_image_lang`);

--
-- Indexes for table `ir_slider_image_lang`
--
ALTER TABLE `ir_slider_image_lang`
  ADD PRIMARY KEY (`id_slider_image_lang`),
  ADD KEY `id_slider` (`id_slider`),
  ADD KEY `id_image_lang` (`id_image_lang`);

--
-- Indexes for table `ir_social_media`
--
ALTER TABLE `ir_social_media`
  ADD PRIMARY KEY (`id_social_media`);

--
-- Indexes for table `ir_tax_rule`
--
ALTER TABLE `ir_tax_rule`
  ADD PRIMARY KEY (`id_tax_rule`);

--
-- Indexes for table `ir_tax_rule_lang`
--
ALTER TABLE `ir_tax_rule_lang`
  ADD PRIMARY KEY (`id_tax_rule_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_tax_rule` (`id_tax_rule`);

--
-- Indexes for table `ir_type_customize`
--
ALTER TABLE `ir_type_customize`
  ADD PRIMARY KEY (`id_type_customize`);

--
-- Indexes for table `ir_type_customize_lang`
--
ALTER TABLE `ir_type_customize_lang`
  ADD PRIMARY KEY (`id_type_customize_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_type_customize` (`id_type_customize`);

--
-- Indexes for table `ir_type_image`
--
ALTER TABLE `ir_type_image`
  ADD PRIMARY KEY (`id_type_image`);

--
-- Indexes for table `ir_type_image_lang`
--
ALTER TABLE `ir_type_image_lang`
  ADD PRIMARY KEY (`id_type_image_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_type_image` (`id_type_image`);

--
-- Indexes for table `ir_type_of_currency`
--
ALTER TABLE `ir_type_of_currency`
  ADD PRIMARY KEY (`id_type_of_currency`);

--
-- Indexes for table `ir_type_of_currency_lang`
--
ALTER TABLE `ir_type_of_currency_lang`
  ADD PRIMARY KEY (`id_type_of_currency_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_type_of_currency` (`id_type_of_currency`);

--
-- Indexes for table `ir_type_product`
--
ALTER TABLE `ir_type_product`
  ADD PRIMARY KEY (`id_type_product`);

--
-- Indexes for table `ir_type_product_lang`
--
ALTER TABLE `ir_type_product_lang`
  ADD PRIMARY KEY (`id_type_product_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_type_product` (`id_type_product`);
ALTER TABLE `ir_type_product_lang` ADD FULLTEXT KEY `title_type_product_lang` (`title_type_product_lang`);

--
-- Indexes for table `ir_type_promotion`
--
ALTER TABLE `ir_type_promotion`
  ADD PRIMARY KEY (`id_type_promotion`);

--
-- Indexes for table `ir_type_promotion_lang`
--
ALTER TABLE `ir_type_promotion_lang`
  ADD PRIMARY KEY (`id_type_promotion_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_type_promotion` (`id_type_promotion`);

--
-- Indexes for table `ir_type_tag`
--
ALTER TABLE `ir_type_tag`
  ADD PRIMARY KEY (`id_type_tag`);

--
-- Indexes for table `ir_type_tag_lang`
--
ALTER TABLE `ir_type_tag_lang`
  ADD PRIMARY KEY (`id_type_tag_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_type_tag` (`id_type_tag`);

--
-- Indexes for table `ir_type_version`
--
ALTER TABLE `ir_type_version`
  ADD PRIMARY KEY (`id_type_version`);

--
-- Indexes for table `ir_type_version_lang`
--
ALTER TABLE `ir_type_version_lang`
  ADD PRIMARY KEY (`id_type_version_lang`),
  ADD KEY `id_lang` (`id_lang`),
  ADD KEY `id_type_version` (`id_type_version`);

--
-- Indexes for table `ir_user`
--
ALTER TABLE `ir_user`
  ADD PRIMARY KEY (`id_user`),
  ADD UNIQUE KEY `email_user` (`email_user`),
  ADD KEY `id_role` (`id_role`);

--
-- Indexes for table `ir_user_customize`
--
ALTER TABLE `ir_user_customize`
  ADD PRIMARY KEY (`id_user_customize`),
  ADD KEY `id_customize` (`id_customize`),
  ADD KEY `id_user` (`id_user`);

--
-- Indexes for table `ir_user_gallery_image_lang`
--
ALTER TABLE `ir_user_gallery_image_lang`
  ADD PRIMARY KEY (`id_user_gallery_image_lang`),
  ADD KEY `id_user` (`id_user`),
  ADD KEY `id_image_lang` (`id_image_lang`);

--
-- Indexes for table `ir_user_social_media`
--
ALTER TABLE `ir_user_social_media`
  ADD PRIMARY KEY (`id_user_social_media`),
  ADD KEY `id_social_media` (`id_social_media`),
  ADD KEY `id_user` (`id_user`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `ir_api_factura`
--
ALTER TABLE `ir_api_factura`
  MODIFY `ir_api_factura` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_attribute`
--
ALTER TABLE `ir_attribute`
  MODIFY `id_attribute` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `ir_attribute_lang`
--
ALTER TABLE `ir_attribute_lang`
  MODIFY `id_attribute_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `ir_category`
--
ALTER TABLE `ir_category`
  MODIFY `id_category` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `ir_category_lang`
--
ALTER TABLE `ir_category_lang`
  MODIFY `id_category_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `ir_category_lang_image_lang`
--
ALTER TABLE `ir_category_lang_image_lang`
  MODIFY `id_category_lang_image_lang` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_customize`
--
ALTER TABLE `ir_customize`
  MODIFY `id_customize` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `ir_customize_lang`
--
ALTER TABLE `ir_customize_lang`
  MODIFY `id_customize_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT for table `ir_file`
--
ALTER TABLE `ir_file`
  MODIFY `id_file` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_file_lang`
--
ALTER TABLE `ir_file_lang`
  MODIFY `id_file_lang` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_image`
--
ALTER TABLE `ir_image`
  MODIFY `id_image` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `ir_image_lang`
--
ALTER TABLE `ir_image_lang`
  MODIFY `id_image_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `ir_image_lang_version`
--
ALTER TABLE `ir_image_lang_version`
  MODIFY `id_image_lang_version` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `ir_image_section`
--
ALTER TABLE `ir_image_section`
  MODIFY `id_image_section` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `ir_image_section_lang`
--
ALTER TABLE `ir_image_section_lang`
  MODIFY `id_image_section_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `ir_lang`
--
ALTER TABLE `ir_lang`
  MODIFY `id_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `ir_menu`
--
ALTER TABLE `ir_menu`
  MODIFY `id_menu` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `ir_menu_image`
--
ALTER TABLE `ir_menu_image`
  MODIFY `id_menu_image` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `ir_menu_lang`
--
ALTER TABLE `ir_menu_lang`
  MODIFY `id_menu_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `ir_product`
--
ALTER TABLE `ir_product`
  MODIFY `id_product` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `ir_product_category`
--
ALTER TABLE `ir_product_category`
  MODIFY `id_product_category` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `ir_product_lang`
--
ALTER TABLE `ir_product_lang`
  MODIFY `id_product_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `ir_product_lang_additional_information`
--
ALTER TABLE `ir_product_lang_additional_information`
  MODIFY `id_product_lang_additional_information` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_product_lang_attribute`
--
ALTER TABLE `ir_product_lang_attribute`
  MODIFY `id_product_lang_attribute` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_product_lang_image_lang`
--
ALTER TABLE `ir_product_lang_image_lang`
  MODIFY `id_product_lang_image_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `ir_product_lang_presentation`
--
ALTER TABLE `ir_product_lang_presentation`
  MODIFY `id_product_lang_presentation` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_product_lang_presentation_image_lang`
--
ALTER TABLE `ir_product_lang_presentation_image_lang`
  MODIFY `id_product_lang_presentation_image_lang` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_product_lang_presentation_lang`
--
ALTER TABLE `ir_product_lang_presentation_lang`
  MODIFY `id_product_lang_presentation_lang` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_product_lang_promotion`
--
ALTER TABLE `ir_product_lang_promotion`
  MODIFY `id_product_lang_promotion` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_promotion`
--
ALTER TABLE `ir_promotion`
  MODIFY `id_promotion` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_promotion_lang`
--
ALTER TABLE `ir_promotion_lang`
  MODIFY `id_promotion_lang` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_record`
--
ALTER TABLE `ir_record`
  MODIFY `id_record` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `ir_regimen_fiscal`
--
ALTER TABLE `ir_regimen_fiscal`
  MODIFY `id_regimen_fiscal` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `ir_regimen_fiscal_lang`
--
ALTER TABLE `ir_regimen_fiscal_lang`
  MODIFY `id_regimen_fiscal_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `ir_role`
--
ALTER TABLE `ir_role`
  MODIFY `id_role` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `ir_role_lang`
--
ALTER TABLE `ir_role_lang`
  MODIFY `id_role_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `ir_session_attempt`
--
ALTER TABLE `ir_session_attempt`
  MODIFY `id_session_attempt` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_slider`
--
ALTER TABLE `ir_slider`
  MODIFY `id_slider` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `ir_slider_image_lang`
--
ALTER TABLE `ir_slider_image_lang`
  MODIFY `id_slider_image_lang` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_social_media`
--
ALTER TABLE `ir_social_media`
  MODIFY `id_social_media` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `ir_tax_rule`
--
ALTER TABLE `ir_tax_rule`
  MODIFY `id_tax_rule` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `ir_tax_rule_lang`
--
ALTER TABLE `ir_tax_rule_lang`
  MODIFY `id_tax_rule_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `ir_type_customize`
--
ALTER TABLE `ir_type_customize`
  MODIFY `id_type_customize` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `ir_type_customize_lang`
--
ALTER TABLE `ir_type_customize_lang`
  MODIFY `id_type_customize_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `ir_type_image`
--
ALTER TABLE `ir_type_image`
  MODIFY `id_type_image` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `ir_type_image_lang`
--
ALTER TABLE `ir_type_image_lang`
  MODIFY `id_type_image_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

--
-- AUTO_INCREMENT for table `ir_type_of_currency`
--
ALTER TABLE `ir_type_of_currency`
  MODIFY `id_type_of_currency` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `ir_type_of_currency_lang`
--
ALTER TABLE `ir_type_of_currency_lang`
  MODIFY `id_type_of_currency_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `ir_type_product`
--
ALTER TABLE `ir_type_product`
  MODIFY `id_type_product` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `ir_type_product_lang`
--
ALTER TABLE `ir_type_product_lang`
  MODIFY `id_type_product_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `ir_type_promotion`
--
ALTER TABLE `ir_type_promotion`
  MODIFY `id_type_promotion` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `ir_type_promotion_lang`
--
ALTER TABLE `ir_type_promotion_lang`
  MODIFY `id_type_promotion_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `ir_type_tag`
--
ALTER TABLE `ir_type_tag`
  MODIFY `id_type_tag` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `ir_type_tag_lang`
--
ALTER TABLE `ir_type_tag_lang`
  MODIFY `id_type_tag_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `ir_type_version`
--
ALTER TABLE `ir_type_version`
  MODIFY `id_type_version` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `ir_type_version_lang`
--
ALTER TABLE `ir_type_version_lang`
  MODIFY `id_type_version_lang` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `ir_user`
--
ALTER TABLE `ir_user`
  MODIFY `id_user` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `ir_user_customize`
--
ALTER TABLE `ir_user_customize`
  MODIFY `id_user_customize` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `ir_user_gallery_image_lang`
--
ALTER TABLE `ir_user_gallery_image_lang`
  MODIFY `id_user_gallery_image_lang` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ir_user_social_media`
--
ALTER TABLE `ir_user_social_media`
  MODIFY `id_user_social_media` int NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `ir_attribute`
--
ALTER TABLE `ir_attribute`
  ADD CONSTRAINT `ir_attribute_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `ir_user` (`id_user`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_attribute_lang`
--
ALTER TABLE `ir_attribute_lang`
  ADD CONSTRAINT `ir_attribute_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_attribute_lang_ibfk_2` FOREIGN KEY (`id_attribute`) REFERENCES `ir_attribute` (`id_attribute`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_category`
--
ALTER TABLE `ir_category`
  ADD CONSTRAINT `ir_category_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `ir_user` (`id_user`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_category_lang`
--
ALTER TABLE `ir_category_lang`
  ADD CONSTRAINT `ir_category_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_category_lang_ibfk_2` FOREIGN KEY (`id_category`) REFERENCES `ir_category` (`id_category`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_category_lang_image_lang`
--
ALTER TABLE `ir_category_lang_image_lang`
  ADD CONSTRAINT `ir_category_lang_image_lang_ibfk_1` FOREIGN KEY (`id_category_lang`) REFERENCES `ir_category_lang` (`id_category_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_category_lang_image_lang_ibfk_2` FOREIGN KEY (`id_image_section_lang`) REFERENCES `ir_image_section_lang` (`id_image_section_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_category_lang_image_lang_ibfk_3` FOREIGN KEY (`id_image_lang`) REFERENCES `ir_image_lang` (`id_image_lang`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_customize`
--
ALTER TABLE `ir_customize`
  ADD CONSTRAINT `ir_customize_ibfk_1` FOREIGN KEY (`id_type_customize`) REFERENCES `ir_type_customize` (`id_type_customize`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_customize_lang`
--
ALTER TABLE `ir_customize_lang`
  ADD CONSTRAINT `ir_customize_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_customize_lang_ibfk_2` FOREIGN KEY (`id_customize`) REFERENCES `ir_customize` (`id_customize`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_file_lang`
--
ALTER TABLE `ir_file_lang`
  ADD CONSTRAINT `ir_file_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_file_lang_ibfk_2` FOREIGN KEY (`id_file`) REFERENCES `ir_file` (`id_file`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_image`
--
ALTER TABLE `ir_image`
  ADD CONSTRAINT `ir_image_ibfk_1` FOREIGN KEY (`id_type_image`) REFERENCES `ir_type_image` (`id_type_image`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_image_lang`
--
ALTER TABLE `ir_image_lang`
  ADD CONSTRAINT `ir_image_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_image_lang_ibfk_2` FOREIGN KEY (`id_image`) REFERENCES `ir_image` (`id_image`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_image_lang_version`
--
ALTER TABLE `ir_image_lang_version`
  ADD CONSTRAINT `ir_image_lang_version_ibfk_1` FOREIGN KEY (`id_image_lang`) REFERENCES `ir_image_lang` (`id_image_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_image_lang_version_ibfk_2` FOREIGN KEY (`id_type_version`) REFERENCES `ir_type_version` (`id_type_version`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_image_section_lang`
--
ALTER TABLE `ir_image_section_lang`
  ADD CONSTRAINT `ir_image_section_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_image_section_lang_ibfk_2` FOREIGN KEY (`id_image_section`) REFERENCES `ir_image_section` (`id_image_section`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_menu_image`
--
ALTER TABLE `ir_menu_image`
  ADD CONSTRAINT `ir_menu_image_ibfk_1` FOREIGN KEY (`id_menu`) REFERENCES `ir_menu` (`id_menu`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_menu_image_ibfk_2` FOREIGN KEY (`id_image`) REFERENCES `ir_image` (`id_image`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_menu_lang`
--
ALTER TABLE `ir_menu_lang`
  ADD CONSTRAINT `ir_menu_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_menu_lang_ibfk_2` FOREIGN KEY (`id_menu`) REFERENCES `ir_menu` (`id_menu`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_product`
--
ALTER TABLE `ir_product`
  ADD CONSTRAINT `ir_product_ibfk_1` FOREIGN KEY (`id_type_product`) REFERENCES `ir_type_product` (`id_type_product`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_product_category`
--
ALTER TABLE `ir_product_category`
  ADD CONSTRAINT `ir_product_category_ibfk_1` FOREIGN KEY (`id_product`) REFERENCES `ir_product` (`id_product`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_product_category_ibfk_2` FOREIGN KEY (`id_category`) REFERENCES `ir_category` (`id_category`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_product_lang`
--
ALTER TABLE `ir_product_lang`
  ADD CONSTRAINT `ir_product_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_product_lang_ibfk_2` FOREIGN KEY (`id_product`) REFERENCES `ir_product` (`id_product`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_product_lang_ibfk_3` FOREIGN KEY (`id_tax_rule`) REFERENCES `ir_tax_rule` (`id_tax_rule`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_product_lang_ibfk_4` FOREIGN KEY (`id_type_of_currency`) REFERENCES `ir_type_of_currency` (`id_type_of_currency`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_product_lang_additional_information`
--
ALTER TABLE `ir_product_lang_additional_information`
  ADD CONSTRAINT `ir_product_lang_additional_information_ibfk_1` FOREIGN KEY (`id_type_tag`) REFERENCES `ir_type_tag` (`id_type_tag`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_product_lang_additional_information_ibfk_2` FOREIGN KEY (`id_product_lang`) REFERENCES `ir_product_lang` (`id_product_lang`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_product_lang_attribute`
--
ALTER TABLE `ir_product_lang_attribute`
  ADD CONSTRAINT `ir_product_lang_attribute_ibfk_1` FOREIGN KEY (`id_product_lang_presentation`) REFERENCES `ir_product_lang_presentation` (`id_product_lang_presentation`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_product_lang_attribute_ibfk_2` FOREIGN KEY (`id_attribute`) REFERENCES `ir_attribute` (`id_attribute`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_product_lang_image_lang`
--
ALTER TABLE `ir_product_lang_image_lang`
  ADD CONSTRAINT `ir_product_lang_image_lang_ibfk_1` FOREIGN KEY (`id_product_lang`) REFERENCES `ir_product_lang` (`id_product_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_product_lang_image_lang_ibfk_2` FOREIGN KEY (`id_image_lang`) REFERENCES `ir_image_lang` (`id_image_lang`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_product_lang_presentation`
--
ALTER TABLE `ir_product_lang_presentation`
  ADD CONSTRAINT `ir_product_lang_presentation_ibfk_1` FOREIGN KEY (`id_product_lang`) REFERENCES `ir_product_lang` (`id_product_lang`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_product_lang_presentation_image_lang`
--
ALTER TABLE `ir_product_lang_presentation_image_lang`
  ADD CONSTRAINT `ir_product_lang_presentation_image_lang_ibfk_1` FOREIGN KEY (`id_product_lang_presentation`) REFERENCES `ir_product_lang_presentation` (`id_product_lang_presentation`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_product_lang_presentation_image_lang_ibfk_2` FOREIGN KEY (`id_image_lang`) REFERENCES `ir_image_lang` (`id_image_lang`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_product_lang_presentation_lang`
--
ALTER TABLE `ir_product_lang_presentation_lang`
  ADD CONSTRAINT `ir_product_lang_presentation_lang_ibfk_1` FOREIGN KEY (`id_product_lang_presentation`) REFERENCES `ir_product_lang_presentation` (`id_product_lang_presentation`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_product_lang_promotion`
--
ALTER TABLE `ir_product_lang_promotion`
  ADD CONSTRAINT `ir_product_lang_promotion_ibfk_1` FOREIGN KEY (`id_product_lang`) REFERENCES `ir_product_lang` (`id_product_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_product_lang_promotion_ibfk_2` FOREIGN KEY (`id_type_promotion`) REFERENCES `ir_type_promotion` (`id_type_promotion`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_promotion_lang`
--
ALTER TABLE `ir_promotion_lang`
  ADD CONSTRAINT `ir_promotion_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_promotion_lang_ibfk_2` FOREIGN KEY (`id_promotion`) REFERENCES `ir_promotion` (`id_promotion`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_record`
--
ALTER TABLE `ir_record`
  ADD CONSTRAINT `ir_record_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `ir_user` (`id_user`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_regimen_fiscal_lang`
--
ALTER TABLE `ir_regimen_fiscal_lang`
  ADD CONSTRAINT `ir_regimen_fiscal_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_regimen_fiscal_lang_ibfk_2` FOREIGN KEY (`id_regimen_fiscal`) REFERENCES `ir_regimen_fiscal` (`id_regimen_fiscal`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_role_lang`
--
ALTER TABLE `ir_role_lang`
  ADD CONSTRAINT `ir_role_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_role_lang_ibfk_2` FOREIGN KEY (`id_role`) REFERENCES `ir_role` (`id_role`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_session_attempt`
--
ALTER TABLE `ir_session_attempt`
  ADD CONSTRAINT `ir_session_attempt_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `ir_user` (`id_user`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_slider`
--
ALTER TABLE `ir_slider`
  ADD CONSTRAINT `ir_slider_ibfk_1` FOREIGN KEY (`id_image_lang`) REFERENCES `ir_image_lang` (`id_image_lang`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_slider_image_lang`
--
ALTER TABLE `ir_slider_image_lang`
  ADD CONSTRAINT `ir_slider_image_lang_ibfk_1` FOREIGN KEY (`id_slider`) REFERENCES `ir_slider` (`id_slider`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_slider_image_lang_ibfk_2` FOREIGN KEY (`id_image_lang`) REFERENCES `ir_image_lang` (`id_image_lang`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_tax_rule_lang`
--
ALTER TABLE `ir_tax_rule_lang`
  ADD CONSTRAINT `ir_tax_rule_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_tax_rule_lang_ibfk_2` FOREIGN KEY (`id_tax_rule`) REFERENCES `ir_tax_rule` (`id_tax_rule`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_type_customize_lang`
--
ALTER TABLE `ir_type_customize_lang`
  ADD CONSTRAINT `ir_type_customize_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_type_customize_lang_ibfk_2` FOREIGN KEY (`id_type_customize`) REFERENCES `ir_type_customize` (`id_type_customize`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_type_image_lang`
--
ALTER TABLE `ir_type_image_lang`
  ADD CONSTRAINT `ir_type_image_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_type_image_lang_ibfk_2` FOREIGN KEY (`id_type_image`) REFERENCES `ir_type_image` (`id_type_image`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_type_of_currency_lang`
--
ALTER TABLE `ir_type_of_currency_lang`
  ADD CONSTRAINT `ir_type_of_currency_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_type_of_currency_lang_ibfk_2` FOREIGN KEY (`id_type_of_currency`) REFERENCES `ir_type_of_currency` (`id_type_of_currency`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_type_product_lang`
--
ALTER TABLE `ir_type_product_lang`
  ADD CONSTRAINT `ir_type_product_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_type_product_lang_ibfk_2` FOREIGN KEY (`id_type_product`) REFERENCES `ir_type_product` (`id_type_product`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_type_promotion_lang`
--
ALTER TABLE `ir_type_promotion_lang`
  ADD CONSTRAINT `ir_type_promotion_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_type_promotion_lang_ibfk_2` FOREIGN KEY (`id_type_promotion`) REFERENCES `ir_type_promotion` (`id_type_promotion`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_type_tag_lang`
--
ALTER TABLE `ir_type_tag_lang`
  ADD CONSTRAINT `ir_type_tag_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_type_tag_lang_ibfk_2` FOREIGN KEY (`id_type_tag`) REFERENCES `ir_type_tag` (`id_type_tag`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_type_version_lang`
--
ALTER TABLE `ir_type_version_lang`
  ADD CONSTRAINT `ir_type_version_lang_ibfk_1` FOREIGN KEY (`id_lang`) REFERENCES `ir_lang` (`id_lang`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_type_version_lang_ibfk_2` FOREIGN KEY (`id_type_version`) REFERENCES `ir_type_version` (`id_type_version`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_user`
--
ALTER TABLE `ir_user`
  ADD CONSTRAINT `ir_user_ibfk_1` FOREIGN KEY (`id_role`) REFERENCES `ir_role_lang` (`id_role`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_user_customize`
--
ALTER TABLE `ir_user_customize`
  ADD CONSTRAINT `ir_user_customize_ibfk_1` FOREIGN KEY (`id_customize`) REFERENCES `ir_customize` (`id_customize`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_user_customize_ibfk_2` FOREIGN KEY (`id_user`) REFERENCES `ir_user` (`id_user`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_user_gallery_image_lang`
--
ALTER TABLE `ir_user_gallery_image_lang`
  ADD CONSTRAINT `ir_user_gallery_image_lang_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `ir_user` (`id_user`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_user_gallery_image_lang_ibfk_2` FOREIGN KEY (`id_image_lang`) REFERENCES `ir_image_lang` (`id_image_lang`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ir_user_social_media`
--
ALTER TABLE `ir_user_social_media`
  ADD CONSTRAINT `ir_user_social_media_ibfk_1` FOREIGN KEY (`id_social_media`) REFERENCES `ir_social_media` (`id_social_media`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ir_user_social_media_ibfk_2` FOREIGN KEY (`id_user`) REFERENCES `ir_user` (`id_user`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
