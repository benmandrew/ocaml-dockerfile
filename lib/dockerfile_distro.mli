(*
 * Copyright (c) 2016 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

(** Run OPAM commands across a matrix of Docker containers.
    Each of these containers represents a different version of
    OCaml, OPAM and an OS distribution (such as Debian or Alpine).
  *)

(** {2 Known distributions and OCaml variants} *)

type t = [ 
  | `Alpine of [ `V3_3 ]
  | `CentOS of [ `V6 | `V7 ]
  | `Debian of [ `Stable | `Testing | `Unstable ]
  | `Fedora of [ `V21 | `V22 | `V23 ]
  | `OracleLinux of [ `V7 ]
  | `Ubuntu of [ `V14_04 | `V15_04 | `V15_10 ]
] with sexp 
(** Supported Docker container distributions *)

val distros : t list
(** Enumeration of the supported Docker container distributions *)

val ocaml_versions : Bytes.t list
(** Enumeration of supported OCaml compiler versions. *)

val opam_versions : Bytes.t list
(** Enumeration of supported OPAM package manager versions. *)

val tag_of_distro : t -> Bytes.t
(** Convert a distribution to a Docker Hub tag.  The full
  form of this is [ocaml/TAG] on the Docker Hub. *)

val opam_tag_of_distro : t -> Bytes.t -> Bytes.t
(** [opam_tag_of_distro distro ocaml_version] will generate
  a Docker Hub tag that maps to the container that matches
  the OS/OCaml combination.  They can be found by default in
  the [ocaml] organisation in Docker Hub. *)

(** {2 Dockerfile generation} *)

val to_dockerfile :
  ocaml_version:Bytes.t ->
  distro:t -> Dockerfile.t
(** [to_dockerfile ~ocaml_version ~distro] generates
   a Dockerfile for [distro], with OPAM installed and the
   current switch pointing to [ocaml_version]. *)

val dockerfile_matrix : (t * Bytes.t * Dockerfile.t) list
(** [dockerfile_matrix] contains the list of Docker tags
   and their associated Dockerfiles for all distributions.
   The user of the container can assume that OPAM is installed
   and initialised to the central remote, and that [opam depext]
   is available on that container. *)

(** {2 Dockerfile generators and iterators } *)

val map :
  ?org:Bytes.t ->
  (distro:t -> ocaml_version:Bytes.t -> Dockerfile.t -> 'a) ->
  'a list
(* [map ?org fn] will map all the supported Docker containers across [fn].
   [fn] will be passed the {!distro}, OCaml compiler version and a base
   Dockerfile that is based off a Docker Hub image from the [org] organisation
   (by default, this is [ocaml/opam]. *)

val map_tag :
  (distro:t -> ocaml_version:Bytes.t -> 'a) -> 'a list
(** [map_tag fn] executes [fn distro ocaml_version] with a tag suitable for use
   against the [ocaml/opam:TAG] Docker Hub. *)

val generate_dockerfiles :
  (Bytes.t * Dockerfile.t) list -> string -> unit
(** [generate_dockerfiles (name * docker) output_dir] will
    output a list of Dockerfiles inside the [output_dir/name] subdirectory,
    with each directory containing the Dockerfile specified by [docker]. *)

val generate_dockerfiles_in_git_branches :
  (Bytes.t * Dockerfile.t) list -> string -> unit
(** [generate_dockerfiles_in_git_branches (name * docker) output_dir] will
    output a set of git branches in the [output_dir] Git repository.
    Each branch will be named [name] and contain a single [docker] file.
    The contents of these branches will be reset, so this should be
    only be used on an [output_dir] that is a dedicated Git repository
    for this purpose. *)
