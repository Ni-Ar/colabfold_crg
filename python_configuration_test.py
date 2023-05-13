import tensorflow as tf
import jax
import jaxlib

print("TensorFlow version: ", tf.__version__)
print("jax version: ", jax.__version__)
print("jaxlib version: ", jaxlib.__version__)

physical_CPU_devices = tf.config.list_physical_devices('CPU')
print("Num of CPU seen by tensorflow: ", len(physical_CPU_devices))

physical_GPU_devices = tf.config.list_physical_devices('GPU')
print("Num of GPU seen by tensorflow: ", len(physical_GPU_devices))

print("jax devices: ", jax.devices())
print("jax local device count: ", jax.local_device_count())

