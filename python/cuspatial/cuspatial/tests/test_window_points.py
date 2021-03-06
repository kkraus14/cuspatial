# Copyright (c) 2019, NVIDIA CORPORATION.

import pytest
import cudf
from cudf.tests.utils import assert_eq
import numpy as np
import cuspatial


def test_zeros():
    with pytest.raises(RuntimeError):
        result = cuspatial.window_points(
            0, 0, 0, 0, cudf.Series([0.0]), cudf.Series([0.0])
        )

def test_ones():
    with pytest.raises(RuntimeError):
        result = cuspatial.window_points(
            0, 0, 0, 0, cudf.Series([0.0]), cudf.Series([0.0])
        )

def test_centered():
    result = cuspatial.window_points(
        -1, -1, 1, 1, cudf.Series([0.0]), cudf.Series([0.0])
    )
    assert_eq(result, cudf.DataFrame({'x': [0.0], 'y': [0.0]}))

@pytest.mark.parametrize('coords', [
    (-1.0, -1.0),
    (-1.0, 1.0),
    (1.0, -1.0),
    (1.0, 1.0)
])
def test_corners(coords):
    x, y = coords
    result = cuspatial.window_points(
        -1.1, -1.1, 1.1, 1.1, cudf.Series([x]), cudf.Series([y])
    )
    assert_eq(result, cudf.DataFrame({'x': [x], 'y': [y]}))

def test_pair():
    result = cuspatial.window_points(
        -1.1, -1.1, 1.1, 1.1, cudf.Series([0, 1]), cudf.Series([1, 0])
    )
    assert_eq(result, cudf.DataFrame({'x': [0.0, 1], 'y': [1, 0.0]}))

def test_oob():
    result = cuspatial.window_points(
        -1, -1, 1, 1, cudf.Series([-2, 2]), cudf.Series([2, -2])
    )
    assert_eq(result, cudf.DataFrame({'x': [], 'y': []}))

def test_half():
    result = cuspatial.window_points(
        -2, -2, 2, 2,
        cudf.Series([-1.0, 1.0, 3.0, -3.0]),
        cudf.Series([1.0, -1.0, 3.0, -3.0])
    )
    print(result)
    assert_eq(result, cudf.DataFrame({'x': [-1.0, 1.0], 'y': [1.0, -1.0]}))

