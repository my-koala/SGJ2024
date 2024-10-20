@tool
extends Area2D
class_name Carriable2D

signal carry_started()
signal carry_stopped()

var _carrier: Carrier2D = null
